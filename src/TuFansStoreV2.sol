// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./interface/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TuFansTokenSale is ReentrancyGuard, Ownable {
    IERC20 public tokenTuFans; // Polygon Mumbai = 0xFbEb43a7ab0755b1Ba88AD97160E656b36C91Abf
    IERC20 public usdc; // Polygon Mumbai = 

    uint256 public price = 1; // 1 = 1 USDC, 15 = 1.5 USDC, 2 = 2 USDC
    uint256 public feePercentage = 2;
    address private constant TREASURY_ADDRESS = 0x20217905650216527f63FAC692341C6fD40CC5D4; // ADDRESS 2
    address private constant MARKETING_ADDRESS = 0x60D0bD899Eab506732Ecd9822e8d6893527D2830; // ADDRESS 3
    uint256 public immutable DECIMALS_TOKEN; // 18;
    uint256 public immutable DECIMALS_USDC; // 6;

    constructor(IERC20 _token, IERC20 _usdc) Ownable(msg.sender) {
        tokenTuFans = _token;
        usdc = _usdc;   
        DECIMALS_TOKEN = tokenTuFans.decimals();
        DECIMALS_USDC = usdc.decimals();     
    }

    event TokenBought(address indexed buyer, uint256 amount, uint256 totalCost, uint256 fee, uint256 finalCost);

    function buyTokens(uint256 _amount) external nonReentrant {
        (uint256 totalWithoutFee, uint256 fee , uint256 totalWithFee ) = _getAmountToTransferInUSDC(_amount);

        require(tokenTuFans.balanceOf(address(this)) >= _amount, "Not enough Token to Transfer");
        require(usdc.balanceOf(msg.sender) >= totalWithFee, "Not enough USDC");

        emit TokenBought(msg.sender, _amount, totalWithFee, fee, totalWithFee);

        // Se transfieren los USDC directo al Treasury
        usdc.transferFrom(msg.sender, TREASURY_ADDRESS, totalWithoutFee);
        // Se transfieren los USDC directo al address de Marketing
        usdc.transferFrom(msg.sender, MARKETING_ADDRESS, fee);
        // Se transfieren los Tokens al usuario
        tokenTuFans.transfer(msg.sender, _amount);
    }

    function _getAmountToTransferInUSDC(uint256 _amount) public view returns(uint256, uint256, uint256) {
        uint256 amountScaled = _amount / 10**(DECIMALS_TOKEN-DECIMALS_USDC); // LA DIFERENCIA DE AMBOS DECIMALES 18 = EL TOKEN y 6 = USDC da 12

        uint256 totalWithoutFee = amountScaled * price;
        uint256 fee = (totalWithoutFee * feePercentage) / 100;
        uint256 totalWithFee = totalWithoutFee + fee;
        return (totalWithoutFee, fee, totalWithFee);                
    } 

    // Function to withdraw Tokens
    function withdraw() public onlyOwner {
        uint256 balance = tokenTuFans.balanceOf(address(this));
        tokenTuFans.transfer(owner(), balance);
    }
}



