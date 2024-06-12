// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VMD} from "./VMD.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vega_Marketing_DAO is Ownable {

    address public vmdAddress;
    address public tetherAddress;
    uint256 public firstTrancheRate = 200 * 1e12;
    uint256 public secondTrancheRate = 100 * 1e12;
    uint256 public secondTrancheThreshold = 100_000 * 1e6;
    uint256 public secondTrancheLimit = 500_000 * 1e6;
    uint256 public tetherCollected = 0;

    /// @notice Create Vega Maketing DAO contract
    /// @param tetherAddr Tether contract address
    /// @param vmdAddr VMD token address
    constructor(
        address tetherAddr,
        address vmdAddr
    ) Ownable(msg.sender) {
        tetherAddress = tetherAddr;
        vmdAddress = vmdAddr;
    }

    /// @notice Get current exchange rate
    /// @param amount Tether to spend 
    function getExchangeRate(uint256 amount) public view returns(uint256 exchangeRate) {
        if(tetherCollected + amount > secondTrancheThreshold) {
            return secondTrancheRate;
        }
        return firstTrancheRate;
    }

    /// @notice Buy tokens
    /// @param amount Amount of Tether to spend
    function buyTokens(uint256 amount) public {
        require(amount + tetherCollected <= (secondTrancheLimit + secondTrancheThreshold), "Tokens sold out");
        (bool success, bytes memory returndata) = tetherAddress.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                address(this),
                amount
            )
        );
        require(success, "token transfer failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "token transfer failed");
        }
        uint256 exchangeRate = getExchangeRate(amount);
        uint256 tokensToBuy = exchangeRate * amount;
        VMD(vmdAddress).mint(address(this), tokensToBuy);
        VMD(vmdAddress).transfer(msg.sender, tokensToBuy);
        tetherCollected += amount;
    }

    /// @notice Withdraw ERC20
    /// @param tokenAddress ERC20 token address
    function withdrawErc20(address tokenAddress) public onlyOwner {
        uint256 amount = ERC20(tokenAddress).balanceOf(address(this));
        (bool success, bytes memory returndata) = tokenAddress.call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                amount
            )
        );
        require(success, "token transfer failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "token transfer failed");
        }
    }

    /// @notice Transfer ownership of VMD
    /// @param newOwner New owner's address
    function transferVmdOwnership(address newOwner) public onlyOwner {
        VMD(vmdAddress).transferOwnership(newOwner);
    }
}
