// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract USDT_Test is ERC20, Ownable {

    /// @notice Create USDT_Test token
    /// @param name The name of the ERC20 token
    /// @param symbol The symbol of the ERC20 token
    constructor(
        string memory name, 
        string memory symbol
    ) ERC20(name, symbol) Ownable(msg.sender) {
        super._mint(super.owner(), 1000000 * 1e6);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}
