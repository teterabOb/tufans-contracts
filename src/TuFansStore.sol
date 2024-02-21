// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interface/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSale is Ownable {
    IERC20 public tokenForSale;
    IERC20 public paymentToken;
    uint256 public tokenPrice;
    uint8 public actualSale;
    bool public saleActive;

    struct Sale {
        uint256 tokenPrice;
        uint256 tokenAmount;
        uint256 tokenSold;
        uint256 tokenRemaining;
        uint256 startDate;
        uint256 endDate;
    }

    mapping(uint => Sale) public sales;
    //mapping(uint => bool) public saleExists;

    constructor(
        IERC20 _tokenForSale,
        IERC20 _paymentToken
    ) Ownable(msg.sender) {
        tokenForSale = _tokenForSale;
        paymentToken = _paymentToken;
        tokenPrice = 1 * 10 ** 18; // 1 token = 1 paymentToken = 1 USDC
    }

    function adjustTokenAmount(
        uint256 _numTokens
    ) public view returns (uint256) {
        uint256 tokenDecimals = tokenForSale.decimals();
        uint256 paymentDecimals = paymentToken.decimals();

        if (tokenDecimals > paymentDecimals) {
            return _numTokens * (10 ** (tokenDecimals - paymentDecimals));
        } else if (tokenDecimals < paymentDecimals) {
            return _numTokens / (10 ** (paymentDecimals - tokenDecimals));
        } else {
            return _numTokens;
        }
    }
    function buyTokens(uint256 _numTokens) public {
        require(saleActive, "Sale is not active");
        require(_numTokens > 0, "You must buy at least one token");
        require(
            _numTokens <= tokenForSale.balanceOf(address(this)),
            "Not enough tokens for sale"
        );

        uint256 adjustedNumTokens = adjustTokenAmount(_numTokens);
        uint256 totalCost = adjustedNumTokens * tokenPrice;

        paymentToken.transferFrom(msg.sender, address(this), totalCost);
        tokenForSale.transfer(msg.sender, adjustedNumTokens);
    }

    function withdraw() public onlyOwner {
        uint256 balance = paymentToken.balanceOf(address(this));
        paymentToken.transfer(owner(), balance);
    }

    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
        // Number must be sent in WEI = QTY * 10^18 - assuming 18 decimals
        require(_tokenPrice > 0, "Token price must be greater than 0");
        tokenPrice = _tokenPrice;
    }

    function addSale(
        uint256 _tokenPrice,
        uint256 _tokenAmount,
        uint256 _startDate,
        uint256 _endDate
    ) public onlyOwner {
        require(_tokenPrice > 0, "Token price must be greater than 0");
        require(_tokenAmount > 0, "Token amount must be greater than 0");
        require(_startDate > 0, "Start date must be greater than 0");
        require(_endDate > 0, "End date must be greater than 0");
        require(
            _endDate > _startDate,
            "End date must be greater than start date"
        );

        Sale storage newSale = sales[actualSale];
        newSale.tokenPrice = _tokenPrice;
        newSale.tokenAmount = _tokenAmount;
        newSale.tokenRemaining = _tokenAmount;
        newSale.startDate = _startDate;
        newSale.endDate = _endDate;
        sales[actualSale] = newSale;
        actualSale++;
    }

    function disabledSale() public onlyOwner {
        saleActive = false;
    }

    function enableSale() public onlyOwner {
        saleActive = true;
    }

    function paymentTokenDecimals() public view returns (uint8) {
        return paymentToken.decimals();
    }
}
