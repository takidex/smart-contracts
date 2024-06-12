// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TAKI is ERC20, Ownable {

    struct Tranche {
        uint256 vestingStart;
        uint256 vestingEnd;
    }

    struct ExchangeRate {
        uint256 cutoff;
        uint256 value;
        uint256 tranche;
    }

    ExchangeRate[] public exchangeRates;

    address public tetherAddress;

    bool public requireWhitelisted;
    mapping(address => bool) whitelist;

    Tranche[] public tranches;
    mapping(uint256 => mapping(uint256 => Tranche)) public tranchesIndex;

    mapping(uint256 => mapping(address => uint256)) public userAllocatedByTranche;
    mapping(uint256 => mapping(address => uint256)) public userRedeemedByTranche;
    mapping(uint256 => uint256) totalAllocatedByTranche;
    mapping(uint256 => uint256) totalRedeemedByTranche;
    uint256 public totalAllocated;
    uint256 public totalRedeemed;
    uint256 public tokensPurchased;

    /// @notice Create pausable TAKI token with capped supply
    /// @param totalSupply The initial supply to mint, these will be the only tokens minted until after mint_lock_expiry
    /// @param name The name of the ERC20 token
    /// @param symbol The symbol of the ERC20 token
    /// @param owner The token owner address
    /// @param tetherAddr Tether contract address
    constructor(
        uint256 totalSupply, 
        string memory name, 
        string memory symbol,
        address owner,
        address tetherAddr
    ) ERC20(name, symbol) Ownable(owner) {
        mintTotalSupply(totalSupply);
        requireWhitelisted = false;
        tetherAddress = tetherAddr;
        tranches[0] = Tranche(1751241600, 1782777600); // unlock June 2025, vesting for 365 days
        tranches[1] = Tranche(1751241600, 1751241600); // unlock June 2025, vesting for 0 days
        tranches[2] = Tranche(1719705600, 1719705600); // unlock June 2024, vesting for 0 days
        exchangeRates[0] = ExchangeRate(20e6 * 1e18, 200, 0);
        exchangeRates[1] = ExchangeRate(70e6 * 1e18, 100, 0);
        exchangeRates[2] = ExchangeRate(170e6 * 1e18, 33, 0);
        exchangeRates[3] = ExchangeRate(270e6 * 1e18, 10, 1);
    }

    /// @notice Create a new tranche if does not exist
    /// @param vestingStart The timestamp when vesting begins
    /// @param vestingEnd The timestamp when vesting end
    function createTranche(
        uint256 vestingStart, 
        uint256 vestingEnd
    ) public onlyOwner {
        require(vestingStart < vestingEnd, "Vesting must start before it ends");
        Tranche memory existingTranche = tranchesIndex[vestingStart][vestingEnd];
        require(existingTranche.vestingStart == 0, "Tranche already exists");
        uint256 id = tranches.length;
        tranches[id] = Tranche(vestingStart, vestingEnd);
        tranchesIndex[vestingStart][vestingEnd] = tranches[id];
    }

    /// @notice Calculate unallocated tokens
    /// @return unallocated Amount of unallocated tokens
    function unallocatedTokens() public view returns(uint256 unallocated) {
        return super.totalSupply() - totalAllocated;
    }

    /// @notice Issue tokens to tranche and recipient
    /// @param id Tranche ID
    /// @param amount Amount of tokens to issue
    /// @param recipient Recipient of issued tokens
    function issueTokens(
        uint256 id, 
        uint256 amount, 
        address recipient
    ) public onlyOwner {
        Tranche memory tranche = tranches[id];
        require(tranche.vestingStart > 0, "Tranche not found");
        require(amount <= unallocatedTokens(), "Insufficient unallocated tokens");
        userAllocatedByTranche[id][recipient] += amount;
        totalAllocatedByTranche[id] += amount;
        totalAllocated += amount;
    }

    /// @notice Whitelist buyer
    /// @param buyer Buyer address
    function whitelistBuyer(address buyer) public onlyOwner {
        whitelist[buyer] = true;
    }

    /// @notice Remove buyer from whitelist
    /// @param buyer Buyer address
    function removeFromWhitelist(address buyer) public onlyOwner {
        whitelist[buyer] = false;
    }

    /// @notice Buy tokens using whitelisted address
    /// @param amount Amount of Tether to spend
    function buyTokens(uint256 amount) public payable {
        if(requireWhitelisted) {
            require(whitelist[msg.sender], "Address not whitelisted");
        }
        ERC20(tetherAddress).transferFrom(msg.sender, address(this), amount);
        (uint256 exchangeRate, uint256 tranche) = getExchangeRate();
        uint256 tokensToBuy = exchangeRate * amount;
        tokensPurchased += tokensToBuy;
        issueTokens(tranche, tokensToBuy, msg.sender);
    }

    /// @notice Get current exchange rate
    /// @return exchangeRate Current exchange rate
    function getExchangeRate() public view returns (uint256 exchangeRate, uint256 tranche) {
        uint256 currentExchangeRate = 0;
        uint256 trancheForRate = 0;
        for(uint256 i = 0; i < exchangeRates.length; i++) {
            ExchangeRate memory rate = exchangeRates[i];
            if(rate.cutoff > tokensPurchased) {
                currentExchangeRate = rate.value;
                tranche = rate.tranche;
                break;
            }
        }
        return (currentExchangeRate, trancheForRate);
    }

    function getVestedBalance(uint256 id, address recipient) public view returns (uint256 balance) {
        Tranche memory tranche = tranches[id];
        if(tranche.vestingStart == 0) {
            return 0;
        }
        uint256 allocated = userAllocatedByTranche[id][recipient];
        uint256 redeemed = userRedeemedByTranche[id][recipient];
        if(tranche.vestingEnd < block.timestamp) {
            return allocated - redeemed;
        } else if(tranche.vestingStart > block.timestamp) {
            return 0;
        } else {
            
        }
    }

    // /// @notice Redeem tokens from tranche
    // /// @param id Tranche ID
    // function redeemFromTranche(uint256 id) public {
    //     Tranche memory tranche = tranches[id];
    //     require(tranche.vestingStart > 0, "Tranche not found");
    // }

    /// @notice Withdraw Tether
    function withdrawTether() public onlyOwner {
        uint256 amount = ERC20(tetherAddress).balanceOf(address(this));
        ERC20(tetherAddress).transferFrom(address(this), msg.sender, amount);
    }

    /// @notice Withdraw Ether
    function withdrawEther() public onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }

    /// @notice Enable/disable whitelist
    /// @param isRequired true or false
    function setRequireWhitelisted(bool isRequired) public onlyOwner {
        requireWhitelisted = isRequired;
    }

    /// @notice Mint initial supply and assign to token contract
    /// @param totalSupply Total supply of tokens
    function mintTotalSupply(uint256 totalSupply) internal {
        super._mint(address(this), totalSupply);
    }
}
