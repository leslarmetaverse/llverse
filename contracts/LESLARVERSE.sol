//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//    __   __________   ___   ___ 
//   / /  / __/ __/ /  / _ | / _ \
//  / /__/ _/_\ \/ /__/ __ |/ , _/
// /____/___/___/____/_/ |_/_/|_| 
// LESLARVERSE

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./abstracts/core/Tokenomics.sol";
import "./abstracts/core/RFI.sol";
import "./abstracts/features/Expensify.sol";

contract LESLARVERSE is 
	IERC20Metadata, 
	Context, 
	Ownable,
	Tokenomics, 
	RFI,
	Expensify
{
	using SafeMath for uint256;

	constructor() {
		// Set special addresses
		specialAddresses[owner()] = true;
		specialAddresses[address(this)] = true;
		specialAddresses[deadAddr] = true;
		// Set limit exemptions
		LimitExemptions memory exemptions;
		exemptions.fees = true;
		limitExemptions[owner()] = exemptions;
		limitExemptions[address(this)] = exemptions;
	}

/* ------------------------------- IERC20 Meta ------------------------------ */

	function name() external pure override returns(string memory) { return NAME;}
	function symbol() external pure override returns(string memory) { return SYMBOL;}
	function decimals() external pure override returns(uint8) { return DECIMALS; }	

/* ---------------------------------- Circulating Supply ---------------------------------- */

	function totalCirculatingSupply() public view returns(uint256) {
		return _tTotal.sub(balanceOf(deadAddr));
	}

/* -------------------------------- Overrides ------------------------------- */

	function beforeTokenTransfer(address from, address to, uint256 amount) 
		internal 
		override
	{
		// Try to execute all our accumulator features.
		triggerFeatures(from);
	}

	function takeFee(address from, address to) 
		internal 
		view 
		override 
		returns(bool) 
	{
		return canTakeFee(from, to);
	}

/* -------------------------- Accumulator Triggers -------------------------- */

	/**
	* @notice Convenience wrapper function which tries to trigger our custom 
	* features.
	*/
	function triggerFeatures(address from) private {
		uint256 contractTokenBalance = balanceOf(address(this));
		// First determine which triggers can be triggered.
		if (!liquidityPools[from]) {
			// Avoid falling into a tx loop.
			if (!inTriggerProcess) {
				if (canTax(contractTokenBalance)) {
					_triggerTax();
				}
			}
		}
	}

/* ---------------------------- Internal Triggers --------------------------- */

	/**
	* @notice Triggers tax and updates triggerLog
	*/
	function _triggerTax() internal {
		taxify(accumulatedForTax);
	}

/* ---------------------------- External Triggers --------------------------- */

	/**
	* @notice Allows to trigger tax manually.
	*/
	function triggerTax() external onlyOwner {
		uint256 contractTokenBalance = balanceOf(address(this));
		require(canTax(contractTokenBalance), "Not enough tokens accumulated.");
		_triggerTax();
	}
}