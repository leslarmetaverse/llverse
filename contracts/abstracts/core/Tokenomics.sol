// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Tokenomics is IERC20, Ownable {
	using SafeMath for uint256;
    mapping (address => bool) private _isBot;

	// Global toggle to avoid trigger loops
	bool internal inTriggerProcess;

/* ---------------------------------- Token --------------------------------- */

	string internal constant NAME = "LESLARVERSE";
	string internal constant SYMBOL = "LLVERSE";

	uint8 internal constant DECIMALS = 9;
	uint256 internal constant ZEROES = 10 ** DECIMALS;

	uint256 private constant MAX = ~uint256(0);
	uint256 internal constant _tTotal = 1000000000000 * ZEROES;
	uint256 internal _rTotal = (MAX - (MAX % _tTotal));

	address public deadAddr = 0x000000000000000000000000000000000000dEaD;

/* ---------------------------------- EXEMPTION --------------------------------- */

	// Sometimes you just have addresses which should be exempt from any 
	// limitations and fees.
	mapping(address => bool) public specialAddresses;

	// Toggle multiple exemptions from transaction limits.
	struct LimitExemptions {
		bool fees;
	}

	// Keeps a record of addresses with limitation exemptions
	mapping(address => LimitExemptions) internal limitExemptions;

/* ---------------------------------- Transactions ---------------------------------- */

	// To keep track of all LPs.
	mapping(address => bool) public liquidityPools;

	// Convenience enum to differentiate transaction limit types.
	enum TransactionLimitType { TRANSACTION, WALLET, SELL }
	// Convenience enum to differentiate transaction types.
	enum TransactionType { REGULAR, SELL, BUY }

	/**
	* @notice Adds address to a liquidity pool map. Can be called externaly.
	*/
	function addAddressToLPs(address lpAddr) public onlyOwner {
		liquidityPools[lpAddr] = true;
	}

	/**
	* @notice Removes address from a liquidity pool map. Can be called externaly.
	*/
	function removeAddressFromLPs(address lpAddr) public onlyOwner {
		liquidityPools[lpAddr] = false;
	}

	function getTransactionType(address from, address to) 
		internal view returns(TransactionType)
	{
		if (liquidityPools[from] && !liquidityPools[to]) {
			// LP -> addr
			return TransactionType.BUY;
		} else if (!liquidityPools[from] && liquidityPools[to]) {
			// addr -> LP
			return TransactionType.SELL;
		}
		return TransactionType.REGULAR;
	}

/* ---------------------------------- Fees ---------------------------------- */
	uint256 internal _tFeeTotal;

	// To be collected for tax
	uint256 public _taxFee = 75;
	uint256 public _reflectionFee = 25;
	// Used to cache fee when removing fee temporarily.
	uint256 internal _previousTaxFee = _taxFee;
	// Used to cache fee when removing fee temporarily.
	uint256 internal _previousReflectionFee = _reflectionFee;
	// Will keep tabs on the amount which should be taken from wallet for taxes.
	uint256 public accumulatedForTax = 0;

	/**
	 * @notice Allows setting Tax fee.
	 */
	function setTaxFee(uint256 fee)
		external 
		onlyOwner
		sameValue(_taxFee, fee)
	{
		require(fee <= 100, "fee cannot be more than 100%");
		_taxFee = fee;
	}

	function setReflectionFee(uint256 fee)
		external 
		onlyOwner
		sameValue(_reflectionFee, fee)
	{
		require(fee <= 100, "fee cannot be more than 100%");
		_reflectionFee = fee;
	}

	/**
	 * @notice Allows temporarily set all feees to 0. 
	 * It can be restored later to the previous fees.
	 */
	function disableAllFeesTemporarily()
		external
		onlyOwner
	{
		removeAllFee();
	}

	/**
	 * @notice Restore all fees from previously set.
	 */
	function restoreAllFees()
		external
		onlyOwner
	{
		restoreAllFee();
	}

	/**
	 * @notice Temporarily stops all fees. Caches the fees into secondary variables,
	 * so it can be reinstated later.
	 */
	function removeAllFee() internal {
		if (_reflectionFee == 0 && _taxFee == 0) return;

		_previousTaxFee = _taxFee;
		_previousReflectionFee = _reflectionFee;
		_taxFee = 0;
		_reflectionFee = 0;
	}

	/**
	 * @notice Restores all fees removed previously, using cached variables.
	 */
	function restoreAllFee() internal {
		_reflectionFee = _previousReflectionFee;
		_taxFee = _previousTaxFee;
	}

	function calculateTaxFee(
		uint256 amount,
		uint8 multiplier
	) internal view returns(uint256) {
		return amount.mul(_taxFee).mul(multiplier).div(10 ** 2);
	}

	function calculateReflectionFee(
		uint256 amount,
		uint8 multiplier
	) internal view returns(uint256) {
		return amount.mul(_reflectionFee).mul(multiplier).div(10 ** 2);
	}

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
	* @notice Updates old and new wallet fee exemptions.
	*/
	function swapExcludedFromFee(address newWallet, address oldWallet) internal {
		if (oldWallet != address(0)) {
			toggleLimitExemptions(oldWallet, false);
		}
		toggleLimitExemptions(newWallet, true);
	}

/* --------------------------- Triggers and limits -------------------------- */

	// One contract accumulates 0.01% of total supply, trigger tax wallet sendout.
	uint256 public minToTax = _tTotal.mul(1).div(10000);

	/**
	@notice External function allowing to set minimum amount of tokens which trigger
	* tax send out.
	*/
	function setMinToTax(uint256 minTokens) 
		external 
		onlyOwner 
		supplyBounds(minTokens)
	{
		minToTax = minTokens * 10 ** 9;
	}

/* --------------------------------- IERC20 --------------------------------- */
	function totalSupply() external pure override returns(uint256) {
		return _tTotal;
	}

	function totalFees() external view returns(uint256) { 
		return _tFeeTotal; 
	}

/* ---------------------------- Anti Bot System --------------------------- */

    function setAntibot(address account, bool _bot) external onlyOwner{
        require(_isBot[account] != _bot, "Value already set");
        _isBot[account] = _bot;
    }

    function isBot(address account) public view returns(bool){
        return _isBot[account];
    }

/* -------------------------------- Helpers ------------------------------- */

    // Use this in case BNB are sent to the contract by mistake
    function rescueBNB(uint256 weiAmount) external onlyOwner{
        require(address(this).balance >= weiAmount, "insufficient BNB balance");
        payable(msg.sender).transfer(weiAmount);
    }

    function rescueBEP20Tokens(address tokenAddress) external lockTheProcess onlyOwner{
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
		if(tokenAddress == address(this)) {
			// Reset the accumulator, only if tokens actually sent, otherwise we keep
			// acumulating until above mentioned things are fixed.
			accumulatedForTax = 0;
		}
    }

/* -------------------------------- Modifiers ------------------------------- */

	modifier supplyBounds(uint256 minTokens) {
		require(minTokens * 10 ** 9 > 0, "Amount must be more than 0");
		require(minTokens * 10 ** 9 <= _tTotal, "Amount must be not bigger than total supply");
		_;
	}

	modifier sameValue(uint256 firstValue, uint256 secondValue) {
		require(firstValue != secondValue, "Already set to this value.");
		_;
	}

	modifier lockTheProcess {
		inTriggerProcess = true;
		_;
		inTriggerProcess = false;
	}
}