// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../core/Pancake.sol";
import "../core/Tokenomics.sol";
import "../core/RFI.sol";
import "../core/Supply.sol";

abstract contract TxPolice is Tokenomics, Pancake, RFI, Supply {
	using SafeMath for uint256;

	// Global toggle to avoid trigger loops
	bool internal inTriggerProcess;
	modifier lockTheProcess {
		inTriggerProcess = true;
		_;
		inTriggerProcess = false;
	}

	// Sometimes you just have addresses which should be exempt from any 
	// limitations and fees.
	mapping(address => bool) public specialAddresses;

	// Toggle multiple exemptions from transaction limits.
	struct LimitExemptions {
		bool fees;
	}

	// Keeps a record of addresses with limitation exemptions
	mapping(address => LimitExemptions) internal limitExemptions;

/* --------------------------- Exemption Utilities -------------------------- */

	/**
	* @notice External function allowing owner to toggle various limit exemptions
	* for any address.
	*/
	function toggleLimitExemptions(
		address addr, 
		bool feesToggle
	) 
		public 
		onlyOwner
	{
		LimitExemptions memory ex = limitExemptions[addr];
		ex.fees = feesToggle;
		limitExemptions[addr] = ex;
	}

	/**
	* @notice External function allowing owner toggle any address as special address.
	*/
	function toggleSpecialWallets(address specialAddr, bool toggle) 
		external 
		onlyOwner 
	{
		specialAddresses[specialAddr] = toggle;
	}
/* ---------------------------------- Fees ---------------------------------- */

function canTakeFee(address from, address to) 
	internal view returns(bool) 
{	
	bool take = true;
	if (
		limitExemptions[from].fees 
		|| limitExemptions[to].fees 
		|| specialAddresses[from] 
		|| specialAddresses[to]
	) { take = false; }

	return take;
}

	/**
	* @notice Updates old and new wallet fee exemptions.
	*/
	function swapExcludedFromFee(address newWallet, address oldWallet) internal {
		if (oldWallet != address(0)) {
			toggleLimitExemptions(oldWallet, false);
		}
		toggleLimitExemptions(newWallet, true);
	}

}