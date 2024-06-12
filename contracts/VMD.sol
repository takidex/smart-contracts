// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VMD is ERC20, Ownable {

    /// @notice Create VMD token
    /// @param name The name of the ERC20 token
    /// @param symbol The symbol of the ERC20 token
    constructor(
        string memory name, 
        string memory symbol
    ) ERC20(name, symbol) Ownable(msg.sender) {
        // TODO - do nothing
    }

    /// @notice Allow owner to mint tokens
    /// @param recipient Recipient of minted tokens
    /// @param amount Amount of tokens to mint 
    function mint(address recipient, uint256 amount) public onlyOwner {
        super._mint(recipient, amount);
    }
}
