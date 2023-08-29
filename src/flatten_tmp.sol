/// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// Interface that implements the 4626 standard and the implementation functions
interface ITokenizedStrategy is IERC4626, IERC20Permit {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event UpdatePendingManagement(address indexed newPendingManagement);

    event UpdateManagement(address indexed newManagement);

    event UpdateKeeper(address indexed newKeeper);

    event UpdatePerformanceFee(uint16 newPerformanceFee);

    event UpdatePerformanceFeeRecipient(
        address indexed newPerformanceFeeRecipient
    );

    event UpdateProfitMaxUnlockTime(uint256 newProfitMaxUnlockTime);

    event StrategyShutdown();

    event Reported(
        uint256 profit,
        uint256 loss,
        uint256 protocolFees,
        uint256 performanceFees
    );

    /*//////////////////////////////////////////////////////////////
                           INITILIZATION
    //////////////////////////////////////////////////////////////*/

    function init(
        address _asset,
        string memory _name,
        address _management,
        address _performanceFeeRecipient,
        address _keeper
    ) external;

    /*//////////////////////////////////////////////////////////////
                    NON-STANDARD 4626 OPTIONS
    //////////////////////////////////////////////////////////////*/

    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 maxLoss
    ) external returns (uint256);

    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 maxLoss
    ) external returns (uint256);

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    function isKeeperOrManagement(address _sender) external view;

    function isManagement(address _sender) external view;

    function isShutdown() external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                        KEEPERS FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function tend() external;

    function report() external returns (uint256 _profit, uint256 _loss);

    /*//////////////////////////////////////////////////////////////
                        CONSTANTS
    //////////////////////////////////////////////////////////////*/

    function MIN_FEE() external view returns (uint16);

    function MAX_FEE() external view returns (uint16);

    function FACTORY() external view returns (address);

    /*//////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/

    function apiVersion() external view returns (string memory);

    function pricePerShare() external view returns (uint256);

    function totalIdle() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function management() external view returns (address);

    function pendingManagement() external view returns (address);

    function keeper() external view returns (address);

    function performanceFee() external view returns (uint16);

    function performanceFeeRecipient() external view returns (address);

    function fullProfitUnlockDate() external view returns (uint256);

    function profitUnlockingRate() external view returns (uint256);

    function profitMaxUnlockTime() external view returns (uint256);

    function lastReport() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                            SETTERS
    //////////////////////////////////////////////////////////////*/

    function setPendingManagement(address) external;

    function acceptManagement() external;

    function setKeeper(address _keeper) external;

    function setPerformanceFee(uint16 _performanceFee) external;

    function setPerformanceFeeRecipient(
        address _performanceFeeRecipient
    ) external;

    function setProfitMaxUnlockTime(uint256 _profitMaxUnlockTime) external;

    function shutdownStrategy() external;

    function emergencyWithdraw(uint256 _amount) external;

    /*//////////////////////////////////////////////////////////////
                           ERC20 ADD ONS
    //////////////////////////////////////////////////////////////*/

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool);

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);
}

interface IBaseTokenizedStrategy {
    /*//////////////////////////////////////////////////////////////
                            IMMUTABLE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function asset() external view returns (address);

    function availableDepositLimit(
        address _owner
    ) external view returns (uint256);

    function availableWithdrawLimit(
        address _owner
    ) external view returns (uint256);

    function deployFunds(uint256 _assets) external;

    function freeFunds(uint256 _amount) external;

    function harvestAndReport() external returns (uint256);

    function tendThis(uint256 _totalIdle) external;

    function shutdownWithdraw(uint256 _amount) external;

    function tendTrigger() external view returns (bool);
}

interface IStrategy is IBaseTokenizedStrategy, ITokenizedStrategy {
    // Need to override the `asset` function since
    // its defined in both interfaces inherited.
    function asset()
        external
        view
        override(IBaseTokenizedStrategy, IERC4626)
        returns (address);
}

interface IBaseHealthCheck is IStrategy {
    function doHealthCheck() external view returns (bool);

    function profitLimitRatio() external view returns (uint256);

    function lossLimitRatio() external view returns (uint256);

    function setProfitLimitRatio(uint256 _newProfitLimitRatio) external;

    function setLossLimitRatio(uint256 _newLossLimitRatio) external;

    function setDoHealthCheck(bool _doHealthCheck) external;
}

interface IUniswapV3Swapper {
    function minAmountToSell() external view returns (uint256);

    function base() external view returns (address);

    function router() external view returns (address);

    function uniFees(address, address) external view returns (uint24);
}

interface IStrategyInterface is IBaseHealthCheck, IUniswapV3Swapper {
    function baseToken() external view returns (address);

    function depositor() external view returns (address);

    function setStrategyParams(
        uint16 _targetLTVMultiplier,
        uint16 _warningLTVMultiplier,
        uint256 _minToSell,
        bool _leaveDebtBehind,
        uint256 _maxGasPriceToTend
    ) external;

    function initializeCompV3LenderBorrower(
        address _comet,
        uint24 _ethToAssetFee,
        address _depositor
    ) external;
}

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library CometStructs {
    struct AssetInfo {
        uint8 offset;
        address asset;
        address priceFeed;
        uint64 scale;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }

    struct UserBasic {
        int104 principal;
        uint64 baseTrackingIndex;
        uint64 baseTrackingAccrued;
        uint16 assetsIn;
        uint8 _reserved;
    }

    struct TotalsBasic {
        uint64 baseSupplyIndex;
        uint64 baseBorrowIndex;
        uint64 trackingSupplyIndex;
        uint64 trackingBorrowIndex;
        uint104 totalSupplyBase;
        uint104 totalBorrowBase;
        uint40 lastAccrualTime;
        uint8 pauseFlags;
    }

    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    struct RewardOwed {
        address token;
        uint256 owed;
    }

    struct TotalsCollateral {
        uint128 totalSupplyAsset;
        uint128 _reserved;
    }

    struct RewardConfig {
        address token;
        uint64 rescaleFactor;
        bool shouldUpscale;
    }
}

interface Comet is IERC20 {
    function baseScale() external view returns (uint256);

    function supply(address asset, uint256 amount) external;

    function supplyTo(address to, address asset, uint256 amount) external;

    function withdraw(address asset, uint256 amount) external;

    function getSupplyRate(uint256 utilization) external view returns (uint256);

    function getBorrowRate(uint256 utilization) external view returns (uint256);

    function getAssetInfoByAddress(
        address asset
    ) external view returns (CometStructs.AssetInfo memory);

    function getAssetInfo(
        uint8 i
    ) external view returns (CometStructs.AssetInfo memory);

    function borrowBalanceOf(address account) external view returns (uint256);

    function getPrice(address priceFeed) external view returns (uint128);

    function userBasic(
        address
    ) external view returns (CometStructs.UserBasic memory);

    function totalsBasic()
        external
        view
        returns (CometStructs.TotalsBasic memory);

    function userCollateral(
        address,
        address
    ) external view returns (CometStructs.UserCollateral memory);

    function baseTokenPriceFeed() external view returns (address);

    function numAssets() external view returns (uint8);

    function getUtilization() external view returns (uint256);

    function baseTrackingSupplySpeed() external view returns (uint256);

    function baseTrackingBorrowSpeed() external view returns (uint256);

    function totalSupply() external view override returns (uint256);

    function totalBorrow() external view returns (uint256);

    function baseIndexScale() external pure returns (uint64);

    function baseTrackingAccrued(
        address account
    ) external view returns (uint64);

    function totalsCollateral(
        address asset
    ) external view returns (CometStructs.TotalsCollateral memory);

    function baseMinForRewards() external view returns (uint256);

    function baseToken() external view returns (address);

    function accrueAccount(address account) external;

    function isLiquidatable(address _address) external view returns (bool);

    function baseBorrowMin() external view returns (uint256);

    function isSupplyPaused() external view returns (bool);

    function isWithdrawPaused() external view returns (bool);
}

interface CometRewards {
    function getRewardOwed(
        address comet,
        address account
    ) external returns (CometStructs.RewardOwed memory);

    function claim(address comet, address src, bool shouldAccrue) external;

    function rewardsClaimed(
        address comet,
        address account
    ) external view returns (uint256);

    function rewardConfig(
        address comet
    ) external view returns (CometStructs.RewardConfig memory);
}

/**
 * @notice This contract abstracts interactions with Compound V3 protocol, streamlining operations for the main Strategy
 * @dev The Depositor performs several functions:
 *      - Holds and deposits base tokens into Comet, allowing the Strategy to withdraw when repaying debt
 *      - Claims reward tokens from Comet
 *      - Provides view functions for estimating supply, borrow, and reward APRs
 *      - Handles the clone logic, being initially deployed via a Factory and subsequently cloned for each Strategy
 */
contract Depositor {
    using SafeERC20 for ERC20;

    /// Used for cloning
    bool public original = true;

    /// Used for COMP APR calculations
    uint64 internal constant DAYS_PER_YEAR = 365;
    uint64 internal constant SECONDS_PER_DAY = 60 * 60 * 24;
    uint64 internal constant SECONDS_PER_YEAR = 365 days;

    /// Price feeds for the reward apr calculation, can be updated manually if needed
    address public rewardTokenPriceFeed;
    address public baseTokenPriceFeed;

    /// Scaler used in reward apr calculations
    uint256 internal SCALER;

    /// This is the address of the main V3 pool
    Comet public comet;
    /// This is the token we will be borrowing/supplying
    ERC20 public baseToken;
    /// The contract to get rewards from
    CometRewards public constant rewardsContract = CometRewards(0x45939657d1CA34A8FA39A924B71D28Fe8431e581);

    IStrategyInterface public strategy;

    /// The reward token.
    address internal rewardToken;

    modifier onlyManagement() {
        checkManagement();
        _;
    }

    modifier onlyStrategy() {
        checkStrategy();
        _;
    }

    function checkManagement() internal view {
        require(msg.sender == strategy.management(), "!authorized");
    }

    function checkStrategy() internal view {
        require(msg.sender == address(strategy), "!authorized");
    }

    event Cloned(address indexed clone);

    /**
     * @notice Clones the depositor contract for a new strategy
     * @param _comet The address of the Compound market
     * @return newDepositor The address of the cloned depositor contract
     */
    function cloneDepositor(address _comet) external returns (address newDepositor) {
        require(original, "!original");
        newDepositor = _clone(_comet);
    }

    function _clone(address _comet) internal returns (address newDepositor) {
        /// Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            /// EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newDepositor := create(0, clone_code, 0x37)
        }

        Depositor(newDepositor).initialize(_comet);
        emit Cloned(newDepositor);
    }

    /**
     * @notice Initializes the depositor after cloning
     * @param _comet The address of the Compound market
     */
    function initialize(address _comet) public {
        require(address(comet) == address(0), "!initiliazed");
        comet = Comet(_comet);
        baseToken = ERC20(comet.baseToken());

        baseToken.safeApprove(_comet, type(uint256).max);

        rewardToken = rewardsContract.rewardConfig(_comet).token;

        /// For APR calculations
        uint256 BASE_MANTISSA = comet.baseScale();
        uint256 BASE_INDEX_SCALE = comet.baseIndexScale();

        /// This is needed for reward apr calculations based on decimals of asset
        /// we scale rewards per second to the base token decimals and diff between
        /// reward token decimals and the index scale
        SCALER = (BASE_MANTISSA * 1e18) / BASE_INDEX_SCALE;

        /// Default to the base token feed given
        baseTokenPriceFeed = comet.baseTokenPriceFeed();
        /// Default to the COMP/USD feed
        rewardTokenPriceFeed = 0x2A8758b7257102461BC958279054e372C2b1bDE6;
    }

    /**
     * @notice Sets the linked strategy contract
     * @param _strategy The address of the strategy contract
     */
    function setStrategy(address _strategy) external {
        /// Can only set the strategy once
        require(address(strategy) == address(0), "set");

        strategy = IStrategyInterface(_strategy);

        /// Make sure it has the same base token
        require(address(baseToken) == strategy.baseToken(), "!base");
        /// Make sure this contract is set as the depositor
        require(address(this) == address(strategy.depositor()), "!depositor");
    }

    /**
     * @notice Allows management to update price feed addresses
     * @param _baseTokenPriceFeed New base token price feed address
     * @param _rewardTokenPriceFeed New reward token price feed address
     */
    function setPriceFeeds(address _baseTokenPriceFeed, address _rewardTokenPriceFeed) external onlyManagement {
        /// Just check the call doesnt revert. We dont care about the amount returned
        comet.getPrice(_baseTokenPriceFeed);
        comet.getPrice(_rewardTokenPriceFeed);
        baseTokenPriceFeed = _baseTokenPriceFeed;
        rewardTokenPriceFeed = _rewardTokenPriceFeed;
    }

    /**
     * @notice Returns the Compound market balance for this depositor
     * @return The Compound market balance
     */
    function cometBalance() external view returns (uint256) {
        return comet.balanceOf(address(this));
    }

    /**
     * @notice Non-view function to accrue account for the most accurate accounting
     * @return The Compound market balance including accrued interest
     */
    function accruedCometBalance() public returns (uint256) {
        comet.accrueAccount(address(this));
        return comet.balanceOf(address(this));
    }

    /**
     * @notice Withdraws tokens from the Compound market
     * @param _amount The amount of tokens to withdraw
     */
    function withdraw(uint256 _amount) external onlyStrategy {
        if (_amount == 0) return;
        ERC20 _baseToken = baseToken;

        comet.withdraw(address(_baseToken), _amount);

        uint256 balance = _baseToken.balanceOf(address(this));
        require(balance >= _amount, "!bal");
        _baseToken.safeTransfer(address(strategy), balance);
    }

    /**
     * @notice Deposits tokens into the Compound market
     */
    function deposit() external onlyStrategy {
        ERC20 _baseToken = baseToken;
        /// msg.sender has been checked to be strategy
        uint256 _amount = _baseToken.balanceOf(msg.sender);
        if (_amount == 0) return;

        _baseToken.safeTransferFrom(msg.sender, address(this), _amount);
        comet.supply(address(_baseToken), _amount);
    }

    /**
     * @notice Claims accrued reward tokens from the Compound market
     */
    function claimRewards() external onlyStrategy {
        rewardsContract.claim(address(comet), address(this), true);

        uint256 rewardTokenBalance = ERC20(rewardToken).balanceOf(address(this));

        if (rewardTokenBalance > 0) {
            ERC20(rewardToken).safeTransfer(address(strategy), rewardTokenBalance);
        }
    }

    /// ----------------- COMET VIEW FUNCTIONS -----------------

    /// We put these in the depositor contract to save byte code in the main strategy

    /**
     * @notice Calculates accrued reward tokens due to this contract and the base strategy
     * @return The amount of accrued reward tokens
     */
    function getRewardsOwed() external view returns (uint256) {
        CometStructs.RewardConfig memory config = rewardsContract.rewardConfig(address(comet));
        uint256 accrued = comet.baseTrackingAccrued(address(this)) + comet.baseTrackingAccrued(address(strategy));
        if (config.shouldUpscale) {
            accrued *= config.rescaleFactor;
        } else {
            accrued /= config.rescaleFactor;
        }
        uint256 claimed = rewardsContract.rewardsClaimed(address(comet), address(this))
            + rewardsContract.rewardsClaimed(address(comet), address(strategy));

        return accrued > claimed ? accrued - claimed : 0;
    }

    /**
     * @notice Estimates net borrow APR with a given supply amount
     * @param newAmount The amount to supply
     * @return netApr The estimated net borrow APR
     */
    function getNetBorrowApr(uint256 newAmount) public view returns (uint256 netApr) {
        uint256 newUtilization = ((comet.totalBorrow() + newAmount) * 1e18) / (comet.totalSupply() + newAmount);
        uint256 borrowApr = getBorrowApr(newUtilization);
        uint256 supplyApr = getSupplyApr(newUtilization);
        /// Supply rate can be higher than borrow when utilization is very high
        netApr = borrowApr > supplyApr ? borrowApr - supplyApr : 0;
    }

    /**
     * @notice Gets supply APR with a given utilization ratio
     * @param newUtilization The utilization ratio
     * @return The supply APR
     */
    function getSupplyApr(uint256 newUtilization) public view returns (uint256) {
        unchecked {
            return comet.getSupplyRate(
                newUtilization /// New utilization
            ) * SECONDS_PER_YEAR;
        }
    }

    /**
     * @notice Gets borrow APR with a given utilization ratio
     * @param newUtilization The utilization ratio
     * @return The borrow APR
     */
    function getBorrowApr(uint256 newUtilization) public view returns (uint256) {
        unchecked {
            return comet.getBorrowRate(
                newUtilization /// New utilization
            ) * SECONDS_PER_YEAR;
        }
    }

    /**
     * @notice Gets net reward APR with a given supply amount
     * @param newAmount The amount to supply
     * @return The net reward APR
     */
    function getNetRewardApr(uint256 newAmount) public view returns (uint256) {
        unchecked {
            return getRewardAprForBorrowBase(newAmount) + getRewardAprForSupplyBase(newAmount);
        }
    }

    /**
     * @notice Gets reward APR for supplying with a given amount
     * @param newAmount The new amount to supply
     * @return The reward APR in USD as a decimal scaled up by 1e18
     */
    function getRewardAprForSupplyBase(uint256 newAmount) public view returns (uint256) {
        unchecked {
            uint256 rewardToSuppliersPerDay = comet.baseTrackingSupplySpeed() * SECONDS_PER_DAY * SCALER;
            if (rewardToSuppliersPerDay == 0) return 0;
            return (
                (comet.getPrice(rewardTokenPriceFeed) * rewardToSuppliersPerDay)
                    / ((comet.totalSupply() + newAmount) * comet.getPrice(baseTokenPriceFeed))
            ) * DAYS_PER_YEAR;
        }
    }

    /**
     * @notice Gets reward APR for borrowing with a given amount
     * @param newAmount The new amount to borroww
     * @return The reward APR in USD as a decimal scaled up by 1e18
     */
    function getRewardAprForBorrowBase(uint256 newAmount) public view returns (uint256) {
        /// borrowBaseRewardApr = (rewardTokenPriceInUsd * rewardToBorrowersPerDay / (baseTokenTotalBorrow * baseTokenPriceInUsd)) * DAYS_PER_YEAR;
        unchecked {
            uint256 rewardToBorrowersPerDay = comet.baseTrackingBorrowSpeed() * SECONDS_PER_DAY * SCALER;
            if (rewardToBorrowersPerDay == 0) return 0;
            return (
                (comet.getPrice(rewardTokenPriceFeed) * rewardToBorrowersPerDay)
                    / ((comet.totalBorrow() + newAmount) * comet.getPrice(baseTokenPriceFeed))
            ) * DAYS_PER_YEAR;
        }
    }

    /**
     * @notice Allows management to manually withdraw funds
     * @param _amount The amount of tokens to withdraw
     */
    function manualWithdraw(uint256 _amount) external onlyManagement {
        if (_amount != 0) {
            /// Withdraw directly from the comet
            comet.withdraw(address(baseToken), _amount);
        }
        /// Transfer the full loose balance to the strategy
        baseToken.safeTransfer(address(strategy), baseToken.balanceOf(address(this)));
    }
}

// TokenizedStrategy interface used for internal view delegateCalls.

/**
 * @title YearnV3 Base Tokenized Strategy
 * @author yearn.finance
 * @notice
 *  BaseTokenizedStrategy implements all of the required functionality to
 *  seamlessly integrate with the `TokenizedStrategy` implementation contract
 *  allowing anyone to easily build a fully permisionless ERC-4626 compliant
 *  Vault by inheriting this contract and overriding three simple functions.

 *  It utilizes an immutable proxy pattern that allows the BaseTokenizedStrategy
 *  to remain simple and small. All standard logic is held within the
 *  `TokenizedStrategy` and is reused over any n strategies all using the
 *  `fallback` function to delegatecall the implementation so that strategists
 *  can only be concerned with writing their strategy specific code.
 *
 *  This contract should be inherited and the three main abstract methods
 *  `_deployFunds`, `_freeFunds` and `_harvestAndReport` implemented to adapt
 *  the Strategy to the particular needs it has to create a return. There are
 *  other optional methods that can be implemented to further customize of
 *  the strategy if desired.
 *
 *  All default storage for the strategy is controlled and updated by the
 *  `TokenizedStrategy`. The implementation holds a storage struct that
 *  contains all needed global variables in a manual storage slot. This
 *  means strategists can feel free to implement their own custom storage
 *  variables as they need with no concern of collisions. All global variables
 *  can be viewed within the Strategy by a simple call using the
 *  `TokenizedStrategy` variable. IE: TokenizedStrategy.globalVariable();.
 */
abstract contract BaseTokenizedStrategy {
    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Used on TokenizedStrategy callback functions to make sure it is post
     * a delegateCall from this address to the TokenizedStrategy.
     */
    modifier onlySelf() {
        _onlySelf();
        _;
    }

    /**
     * @dev Use to assure that the call is coming from the strategies management.
     */
    modifier onlyManagement() {
        TokenizedStrategy.isManagement(msg.sender);
        _;
    }

    /**
     * @dev Use to assure that the call is coming from either the strategies
     * management or the keeper.
     */
    modifier onlyKeepers() {
        TokenizedStrategy.isKeeperOrManagement(msg.sender);
        _;
    }

    function _onlySelf() internal view {
        require(msg.sender == address(this), "!Authorized");
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /**
     * This is the address of the TokenizedStrategy implementation
     * contract that will be used by all strategies to handle the
     * accounting, logic, storage etc.
     *
     * Any external calls to the that don't hit one of the functions
     * defined in this base or the strategy will end up being forwarded
     * through the fallback function, which will delegateCall this address.
     *
     * This address should be the same for every strategy, never be adjusted
     * and always be checked before any integration with the Strategy.
     */
    address public constant tokenizedStrategyAddress =
        0xAE69a93945133c00B9985D9361A1cd882d107622;

    /*//////////////////////////////////////////////////////////////
                            IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /**
     * This variable is set to address(this) during initialization of each strategy.
     *
     * This can be used to retrieve storage data within the strategy
     * contract as if it were a linked library.
     *
     *       i.e. uint256 totalAssets = TokenizedStrategy.totalAssets()
     *
     * Using address(this) will mean any calls using this variable will lead
     * to a call to itself. Which will hit the fallback function and
     * delegateCall that to the actual TokenizedStrategy.
     */
    ITokenizedStrategy internal immutable TokenizedStrategy;

    // Underlying asset the Strategy is earning yield on.
    address public immutable asset;

    /**
     * @notice Used to initialize the strategy on deployment.
     *
     * This will set the `TokenizedStrategy` variable for easy
     * internal view calls to the implementation. As well as
     * initializing the default storage variables based on the
     * parameters and using the deployer for the permisioned roles.
     *
     * @param _asset Address of the underlying asset.
     * @param _name Name the strategy will use.
     */
    constructor(address _asset, string memory _name) {
        asset = _asset;

        // Set instance of the implementation for internal use.
        TokenizedStrategy = ITokenizedStrategy(address(this));

        // Initilize the strategies storage variables.
        _init(_asset, _name, msg.sender, msg.sender, msg.sender);

        // Store the tokenizedStrategyAddress at the standard implementation
        // address storage slot so etherscan picks up the interface. This gets
        // stored on initialization and never updated.
        assembly {
            sstore(
                // keccak256('eip1967.proxy.implementation' - 1)
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
                tokenizedStrategyAddress
            )
        }
    }

    /*//////////////////////////////////////////////////////////////
                NEEDED TO BE OVERRIDDEN BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Should deploy up to '_amount' of 'asset' in the yield source.
     *
     * This function is called at the end of a {deposit} or {mint}
     * call. Meaning that unless a whitelist is implemented it will
     * be entirely permissionless and thus can be sandwiched or otherwise
     * manipulated.
     *
     * @param _amount The amount of 'asset' that the strategy should attempt
     * to deposit in the yield source.
     */
    function _deployFunds(uint256 _amount) internal virtual;

    /**
     * @dev Will attempt to free the '_amount' of 'asset'.
     *
     * The amount of 'asset' that is already loose has already
     * been accounted for.
     *
     * This function is called during {withdraw} and {redeem} calls.
     * Meaning that unless a whitelist is implemented it will be
     * entirely permissionless and thus can be sandwiched or otherwise
     * manipulated.
     *
     * Should not rely on asset.balanceOf(address(this)) calls other than
     * for diff accounting purposes.
     *
     * Any difference between `_amount` and what is actually freed will be
     * counted as a loss and passed on to the withdrawer. This means
     * care should be taken in times of illiquidity. It may be better to revert
     * if withdraws are simply illiquid so not to realize incorrect losses.
     *
     * @param _amount, The amount of 'asset' to be freed.
     */
    function _freeFunds(uint256 _amount) internal virtual;

    /**
     * @dev Internal function to harvest all rewards, redeploy any idle
     * funds and return an accurate accounting of all funds currently
     * held by the Strategy.
     *
     * This should do any needed harvesting, rewards selling, accrual,
     * redepositing etc. to get the most accurate view of current assets.
     *
     * NOTE: All applicable assets including loose assets should be
     * accounted for in this function.
     *
     * Care should be taken when relying on oracles or swap values rather
     * than actual amounts as all Strategy profit/loss accounting will
     * be done based on this returned value.
     *
     * This can still be called post a shutdown, a strategist can check
     * `TokenizedStrategy.isShutdown()` to decide if funds should be
     * redeployed or simply realize any profits/losses.
     *
     * @return _totalAssets A trusted and accurate account for the total
     * amount of 'asset' the strategy currently holds including idle funds.
     */
    function _harvestAndReport()
        internal
        virtual
        returns (uint256 _totalAssets);

    /*//////////////////////////////////////////////////////////////
                    OPTIONAL TO OVERRIDE BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Optional function for strategist to override that can
     *  be called in between reports.
     *
     * If '_tend' is used tendTrigger() will also need to be overridden.
     *
     * This call can only be called by a permissioned role so may be
     * through protected relays.
     *
     * This can be used to harvest and compound rewards, deposit idle funds,
     * perform needed poisition maintenance or anything else that doesn't need
     * a full report for.
     *
     *   EX: A strategy that can not deposit funds without getting
     *       sandwiched can use the tend when a certain threshold
     *       of idle to totalAssets has been reached.
     *
     * The TokenizedStrategy contract will do all needed debt and idle updates
     * after this has finished and will have no effect on PPS of the strategy
     * till report() is called.
     *
     * @param _totalIdle The current amount of idle funds that are available to deploy.
     */
    function _tend(uint256 _totalIdle) internal virtual {}

    /**
     * @notice Returns weather or not tend() should be called by a keeper.
     * @dev Optional trigger to override if tend() will be used by the strategy.
     * This must be implemented if the strategy hopes to invoke _tend().
     *
     * @return . Should return true if tend() should be called by keeper or false if not.
     */
    function tendTrigger() external view virtual returns (bool) {
        return false;
    }

    /**
     * @notice Gets the max amount of `asset` that an address can deposit.
     * @dev Defaults to an unlimited amount for any address. But can
     * be overriden by strategists.
     *
     * This function will be called before any deposit or mints to enforce
     * any limits desired by the strategist. This can be used for either a
     * traditional deposit limit or for implementing a whitelist etc.
     *
     *   EX:
     *      if(isAllowed[_owner]) return super.availableDepositLimit(_owner);
     *
     * This does not need to take into account any conversion rates
     * from shares to assets. But should know that any non max uint256
     * amounts may be converted to shares. So it is recommended to keep
     * custom amounts low enough as not to cause overflow when multiplied
     * by `totalSupply`.
     *
     * @param . The address that is depositing into the strategy.
     * @return . The available amount the `_owner` can deposit in terms of `asset`
     */
    function availableDepositLimit(
        address /*_owner*/
    ) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice Gets the max amount of `asset` that can be withdrawn.
     * @dev Defaults to an unlimited amount for any address. But can
     * be overriden by strategists.
     *
     * This function will be called before any withdraw or redeem to enforce
     * any limits desired by the strategist. This can be used for illiquid
     * or sandwichable strategies. It should never be lower than `totalIdle`.
     *
     *   EX:
     *       return TokenIzedStrategy.totalIdle();
     *
     * This does not need to take into account the `_owner`'s share balance
     * or conversion rates from shares to assets.
     *
     * @param . The address that is withdrawing from the strategy.
     * @return . The available amount that can be withdrawn in terms of `asset`
     */
    function availableWithdrawLimit(
        address /*_owner*/
    ) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @dev Optional function for a strategist to override that will
     * allow management to manually withdraw deployed funds from the
     * yield source if a strategy is shutdown.
     *
     * This should attempt to free `_amount`, noting that `_amount` may
     * be more than is currently deployed.
     *
     * NOTE: This will not realize any profits or losses. A separate
     * {report} will be needed in order to record any profit/loss. If
     * a report may need to be called after a shutdown it is important
     * to check if the strategy is shutdown during {_harvestAndReport}
     * so that it does not simply re-deploy all funds that had been freed.
     *
     * EX:
     *   if(freeAsset > 0 && !TokenizedStrategy.isShutdown()) {
     *       depositFunds...
     *    }
     *
     * @param _amount The amount of asset to attempt to free.
     */
    function _emergencyWithdraw(uint256 _amount) internal virtual {}

    /*//////////////////////////////////////////////////////////////
                        TokenizedStrategy HOOKS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Should deploy up to '_amount' of 'asset' in yield source.
     * @dev Callback for the TokenizedStrategy to call during a {deposit}
     * or {mint} to tell the strategy it can deploy funds.
     *
     * Since this can only be called after a {deposit} or {mint}
     * delegateCall to the TokenizedStrategy msg.sender == address(this).
     *
     * Unless a whitelist is implemented this will be entirely permissionless
     * and thus can be sandwiched or otherwise manipulated.
     *
     * @param _amount The amount of 'asset' that the strategy should
     * attemppt to deposit in the yield source.
     */
    function deployFunds(uint256 _amount) external onlySelf {
        _deployFunds(_amount);
    }

    /**
     * @notice Will attempt to free the '_amount' of 'asset'.
     * @dev Callback for the TokenizedStrategy to call during a withdraw
     * or redeem to free the needed funds to service the withdraw.
     *
     * This can only be called after a 'withdraw' or 'redeem' delegateCall
     * to the TokenizedStrategy so msg.sender == address(this).
     *
     * @param _amount The amount of 'asset' that the strategy should attempt to free up.
     */
    function freeFunds(uint256 _amount) external onlySelf {
        _freeFunds(_amount);
    }

    /**
     * @notice Returns the accurate amount of all funds currently
     * held by the Strategy.
     * @dev Callback for the TokenizedStrategy to call during a report to
     * get an accurate accounting of assets the strategy controls.
     *
     * This can only be called after a report() delegateCall to the
     * TokenizedStrategy so msg.sender == address(this).
     *
     * @return . A trusted and accurate account for the total amount
     * of 'asset' the strategy currently holds including idle funds.
     */
    function harvestAndReport() external onlySelf returns (uint256) {
        return _harvestAndReport();
    }

    /**
     * @notice Will call the internal '_tend' when a keeper tends the strategy.
     * @dev Callback for the TokenizedStrategy to initiate a _tend call in the strategy.
     *
     * This can only be called after a tend() delegateCall to the TokenizedStrategy
     * so msg.sender == address(this).
     *
     * We name the function `tendThis` so that `tend` calls are forwarded to
     * the TokenizedStrategy so it can do the necessary accounting.

     * @param _totalIdle The amount of current idle funds that can be
     * deployed during the tend
     */
    function tendThis(uint256 _totalIdle) external onlySelf {
        _tend(_totalIdle);
    }

    /**
     * @notice Will call the internal '_emergencyWithdraw' function.
     * @dev Callback for the TokenizedStrategy during an emergency withdraw.
     *
     * This can only be called after a emergencyWithdraw() delegateCall to
     * the TokenizedStrategy so msg.sender == address(this).
     *
     * We name the function `shutdownWithdraw` so that `emergencyWithdraw`
     * calls are forwarded to the TokenizedStrategy so it can do the necessary
     * accounting after the withdraw.
     *
     * @param _amount The amount of asset to attempt to free.
     */
    function shutdownWithdraw(uint256 _amount) external onlySelf {
        _emergencyWithdraw(_amount);
    }

    /**
     * @dev Funciton used on initialization to delegate call the
     * TokenizedStrategy to setup the default storage for the strategy.
     *
     * We cannot use the `TokenizedStrategy` variable call since this
     * contract is not deployed fully yet. So we need to manually
     * delegateCall the TokenizedStrategy.
     *
     * This is the only time an internal delegateCall should not
     * be for a view function
     */
    function _init(
        address _asset,
        string memory _name,
        address _management,
        address _performanceFeeRecipient,
        address _keeper
    ) private {
        (bool success, ) = tokenizedStrategyAddress.delegatecall(
            abi.encodeCall(
                ITokenizedStrategy.init,
                (_asset, _name, _management, _performanceFeeRecipient, _keeper)
            )
        );

        require(success, "init failed");
    }

    // exeute a function on the TokenizedStrategy and return any value.
    fallback() external {
        // load our target address
        address _tokenizedStrategyAddress = tokenizedStrategyAddress;
        // Execute external function using delegatecall and return any value.
        assembly {
            // Copy function selector and any arguments.
            calldatacopy(0, 0, calldatasize())
            // Execute function delegatecall.
            let result := delegatecall(
                gas(),
                _tokenizedStrategyAddress,
                0,
                calldatasize(),
                0,
                0
            )
            // Get any return value
            returndatacopy(0, 0, returndatasize())
            // Return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

/// Uniswap V3 Swapper

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);

    // Taken from https://soliditydeveloper.com/uniswap3
    // Manually added to the interface
    function refundETH() external payable;
}

/**
 *   @title UniswapV3Swapper
 *   @author Yearn.finance
 *   @dev This is a simple contract that can be inherited by any tokenized
 *   strategy that would like to use Uniswap V3 for swaps. It hold all needed
 *   logic to perform both exact input and exact output swaps.
 *
 *   The global addres variables defualt to the ETH mainnet addresses but
 *   remain settable by the inheriting contract to allow for customization
 *   based on needs or chain its used on.
 *
 *   The only variables that are required to be set are the specific fees
 *   for each token pair. The inheriting contract can use the {_setUniFees}
 *   function to easily set this for any token pairs needed.
 */
contract UniswapV3Swapper {
    // Optional Variable to be set to not sell dust.
    uint256 public minAmountToSell;
    // Defualts to WETH on mainnet.
    address public base = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // Defualts to Uniswap V3 router on mainnet.
    address public router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    // Fees for the Uni V3 pools. Each fee should get set each way in
    // the mapping so no matter the direction the correct fee will get
    // returned for any two tokens.
    mapping(address => mapping(address => uint24)) public uniFees;

    /**
     * @dev All fess will defualt to 0 on creation. A strategist will need
     * To set the mapping for the tokens expected to swap. This function
     * is to help set the mapping. It can be called internally during
     * intialization, through permisioned functions etc.
     */
    function _setUniFees(
        address _token0,
        address _token1,
        uint24 _fee
    ) internal {
        uniFees[_token0][_token1] = _fee;
        uniFees[_token1][_token0] = _fee;
    }

    /**
     * @dev Used to swap a specific amount of `_from` to `_to`.
     * This will check and handle all allownaces as well as not swapping
     * unless `_amountIn` is greater than the set `_minAmountOut`
     *
     * If one of the tokens matches with the `base` token it will do only
     * one jump, otherwise will do two jumps.
     *
     * The corresponding uniFees for each token pair will need to be set
     * other wise this function will revert.
     *
     * @param _from The token we are swapping from.
     * @param _to The token we are swapping to.
     * @param _amountIn The amount of `_from` we will swap.
     * @param _minAmountOut The min of `_to` to get out.
     * @return _amountOut The actual amount of `_to` that was swapped to
     */
    function _swapFrom(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _minAmountOut
    ) internal returns (uint256 _amountOut) {
        if (_amountIn > minAmountToSell) {
            _checkAllowance(router, _from, _amountIn);
            if (_from == base || _to == base) {
                ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                    .ExactInputSingleParams(
                        _from, // tokenIn
                        _to, // tokenOut
                        uniFees[_from][_to], // from-to fee
                        address(this), // recipient
                        block.timestamp, // deadline
                        _amountIn, // amountIn
                        _minAmountOut, // amountOut
                        0 // sqrtPriceLimitX96
                    );

                _amountOut = ISwapRouter(router).exactInputSingle(params);
            } else {
                bytes memory path = abi.encodePacked(
                    _from, // tokenIn
                    uniFees[_from][base], // from-base fee
                    base, // base token
                    uniFees[base][_to], // base-to fee
                    _to // tokenOut
                );

                _amountOut = ISwapRouter(router).exactInput(
                    ISwapRouter.ExactInputParams(
                        path,
                        address(this),
                        block.timestamp,
                        _amountIn,
                        _minAmountOut
                    )
                );
            }
        }
    }

    /**
     * @dev Used to swap a specific amount of `_to` from `_from` unless
     * it takes more than `_maxAmountFrom`.
     *
     * This will check and handle all allownaces as well as not swapping
     * unless `_maxAmountFrom` is greater than the set `minAmountToSell`
     *
     * If one of the tokens matches with the `base` token it will do only
     * one jump, otherwise will do two jumps.
     *
     * The corresponding uniFees for each token pair will need to be set
     * other wise this function will revert.
     *
     * @param _from The token we are swapping from.
     * @param _to The token we are swapping to.
     * @param _amountTo The amount of `_to` we need out.
     * @param _maxAmountFrom The max of `_from` we will swap.
     * @return _amountIn The actual amouont of `_from` swapped.
     */
    function _swapTo(
        address _from,
        address _to,
        uint256 _amountTo,
        uint256 _maxAmountFrom
    ) internal returns (uint256 _amountIn) {
        if (_maxAmountFrom > minAmountToSell) {
            _checkAllowance(router, _from, _maxAmountFrom);
            if (_from == base || _to == base) {
                ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
                    .ExactOutputSingleParams(
                        _from, // tokenIn
                        _to, // tokenOut
                        uniFees[_from][_to], // from-to fee
                        address(this), // recipient
                        block.timestamp, // deadline
                        _amountTo, // amountOut
                        _maxAmountFrom, // maxAmountIn
                        0 // sqrtPriceLimitX96
                    );

                _amountIn = ISwapRouter(router).exactOutputSingle(params);
            } else {
                bytes memory path = abi.encodePacked(
                    _to,
                    uniFees[base][_to], // base-to fee
                    base,
                    uniFees[_from][base], // from-base fee
                    _from
                );

                _amountIn = ISwapRouter(router).exactOutput(
                    ISwapRouter.ExactOutputParams(
                        path,
                        address(this),
                        block.timestamp,
                        _amountTo, // How much we want out
                        _maxAmountFrom
                    )
                );
            }
        }
    }

    /**
     * @dev Internal safe function to make sure the contract you want to
     * interact with has enough allowance to pull the desired tokens.
     *
     * @param _contract The address of the contract that will move the token.
     * @param _token The ERC-20 token that will be getting spent.
     * @param _amount The amount of `_token` to be spent.
     */
    function _checkAllowance(
        address _contract,
        address _token,
        uint256 _amount
    ) internal {
        if (ERC20(_token).allowance(address(this), _contract) < _amount) {
            ERC20(_token).approve(_contract, 0);
            ERC20(_token).approve(_contract, _amount);
        }
    }
}

/**
 *   @title Base Health Check
 *   @author Yearn.finance
 *   @notice This contract can be inherited by any Yearn
 *   V3 strategy wishing to implement a health check during
 *   the `report` function in order to prevent any unexpected
 *   behavior from being permanently recorded as well as the
 *   `checkHealth` modifier.
 *
 *   A strategist simply needs to inherit this contract. Set
 *   the limit ratios to the desired amounts and then call
 *   `_executeHealthCheck(...)` during the  `_harvestAndReport()`
 *   execution. If the profit or loss that would be recorded is
 *   outside the acceptable bounds the tx will revert.
 *
 *   The healthcheck does not prevent a strategy from reporting
 *   losses, but rather can make sure manual intervention is
 *   needed before reporting an unexpected loss or profit.
 */
abstract contract BaseHealthCheck is BaseTokenizedStrategy {
    // Optional modifier that can be placed on any function
    // to perform checks such as debt/PPS before running.
    // Must override `_checkHealth()` for this to work.
    modifier checkHealth() {
        _checkHealth();
        _;
    }

    // Can be used to determine if a healthcheck should be called.
    // Defaults to true;
    bool public doHealthCheck = true;

    uint256 internal constant MAX_BPS = 10_000;

    // Default profit limit to 100%.
    uint256 private _profitLimitRatio = MAX_BPS;

    // Defaults loss limit to 0.
    uint256 private _lossLimitRatio;

    constructor(
        address _asset,
        string memory _name
    ) BaseTokenizedStrategy(_asset, _name) {}

    /**
     * @notice Returns the current profit limit ratio.
     * @dev Use a getter function to keep the variable private.
     * @return . The current profit limit ratio.
     */
    function profitLimitRatio() public view returns (uint256) {
        return _profitLimitRatio;
    }

    /**
     * @notice Returns the current loss limit ratio.
     * @dev Use a getter function to keep the variable private.
     * @return . The current loss limit ratio.
     */
    function lossLimitRatio() public view returns (uint256) {
        return _lossLimitRatio;
    }

    /**
     * @notice Set the `profitLimitRatio`.
     * @dev Denominated in basis points. I.E. 1_000 == 10%.
     * @param _newProfitLimitRatio The mew profit limit ratio.
     */
    function setProfitLimitRatio(
        uint256 _newProfitLimitRatio
    ) external onlyManagement {
        _setProfitLimitRatio(_newProfitLimitRatio);
    }

    /**
     * @dev Internally set the profit limit ratio. Denominated
     * in basis points. I.E. 1_000 == 10%.
     * @param _newProfitLimitRatio The mew profit limit ratio.
     */
    function _setProfitLimitRatio(uint256 _newProfitLimitRatio) internal {
        require(_newProfitLimitRatio > 0, "!zero profit");
        _profitLimitRatio = _newProfitLimitRatio;
    }

    /**
     * @notice Set the `lossLimitRatio`.
     * @dev Denominated in basis points. I.E. 1_000 == 10%.
     * @param _newLossLimitRatio The new loss limit ratio.
     */
    function setLossLimitRatio(
        uint256 _newLossLimitRatio
    ) external onlyManagement {
        _setLossLimitRatio(_newLossLimitRatio);
    }

    /**
     * @dev Internally set the loss limit ratio. Denominated
     * in basis points. I.E. 1_000 == 10%.
     * @param _newLossLimitRatio The new loss limit ratio.
     */
    function _setLossLimitRatio(uint256 _newLossLimitRatio) internal {
        require(_newLossLimitRatio < MAX_BPS, "!loss limit");
        _lossLimitRatio = _newLossLimitRatio;
    }

    /**
     * @notice Turns the healthcheck on and off.
     * @dev If turned off the next report will auto turn it back on.
     * @param _doHealthCheck Bool if healthCheck should be done.
     */
    function setDoHealthCheck(bool _doHealthCheck) public onlyManagement {
        doHealthCheck = _doHealthCheck;
    }

    /**
     * @notice Check important invariants for the strategy.
     * @dev This can be overriden to check any important strategy
     *  specific invariants.
     *
     *  NOTE: Should revert if unhealthy for the modifier to work.
     */
    function _checkHealth() internal virtual {}

    /**
     * @dev To be called during a report to make sure the profit
     * or loss being recorded is within the acceptable bound.
     *
     * @param _newTotalAssets The amount that will be reported.
     */
    function _executeHealthCheck(uint256 _newTotalAssets) internal virtual {
        if (!doHealthCheck) {
            doHealthCheck = true;
            return;
        }

        // Get the curent total assets from the implementation.
        uint256 currentTotalAssets = TokenizedStrategy.totalAssets();

        if (_newTotalAssets > currentTotalAssets) {
            require(
                ((_newTotalAssets - currentTotalAssets) <=
                    (currentTotalAssets * _profitLimitRatio) / MAX_BPS),
                "healthCheck"
            );
        } else if (currentTotalAssets > _newTotalAssets) {
            require(
                (currentTotalAssets - _newTotalAssets <=
                    ((currentTotalAssets * _lossLimitRatio) / MAX_BPS)),
                "healthCheck"
            );
        }
    }
}

/**
 * @title CompV3LenderBorrower
 * @author Schlagonia
 * @notice A Yearn V3 lender borrower strategy for Compound V3.
 */
contract Strategy is BaseHealthCheck, UniswapV3Swapper {
    using SafeERC20 for ERC20;

    /// If set to true, the strategy will not try to repay debt by selling rewards or asset.
    bool public preventDebtRepayment;

    /// The address of the main Compound V3 pool
    Comet public immutable comet;
    /// The token we will be borrowing/supplying
    address public immutable baseToken;
    /// The contract to get Comp rewards from
    CometRewards public constant rewardsContract = CometRewards(0x45939657d1CA34A8FA39A924B71D28Fe8431e581);

    address internal constant weth = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    /// The Contract that will deposit the baseToken back into Compound
    Depositor public immutable depositor;

    /// The reward Token
    address public immutable rewardToken;

    /// mapping of price feeds. Management can customize if needed
    mapping(address => address) public priceFeeds;

    /// @notice Target Loan-To-Value (LTV) multiplier.
    /// @dev Represents the ratio up to which we will borrow, relative to the liquidation threshold.
    /// LTV is the debt-to-collateral ratio. Default is set to 70% of the liquidation LTV.
    uint16 public targetLTVMultiplier = 7_000;

    /// @notice Warning Loan-To-Value (LTV) multiplier
    /// @dev Represents the ratio at which we will start repaying the debt to avoid liquidation
    /// Default is set to 80% of the liquidation LTV
    uint16 public warningLTVMultiplier = 8_000;

    /// @notice Slippage tolerance (in basis points) for swaps
    /// Default is set to 5%.
    uint256 public slippage = 500;

    /// Thresholds: lower limit on how much base token can be borrowed at a time.
    uint256 internal immutable minThreshold;

    /// The max the base fee (in gwei) will be for a tend
    uint256 public maxGasPriceToTend = 150 * 1e9;

    /**
     * @param _asset The address of the asset we are lending/borrowing.
     * @param _name The name of the strategy.
     * @param _ethToAssetFee The fee for swapping eth to asset.
     * @param _depositor The address of the depositor contract.
     */
    constructor(address _asset, string memory _name, address _comet, uint24 _ethToAssetFee, address _depositor)
        BaseHealthCheck(_asset, _name)
    {
        comet = Comet(_comet);

        /// Get the baseToken we wil borrow and the min
        baseToken = comet.baseToken();
        minThreshold = comet.baseBorrowMin();

        depositor = Depositor(_depositor);
        require(baseToken == address(depositor.baseToken()), "!base");

        /// Set the rewardToken token we will get
        rewardToken = rewardsContract.rewardConfig(_comet).token;

        /// To supply asset as collateral
        ERC20(asset).safeApprove(_comet, type(uint256).max);
        /// To repay debt
        ERC20(baseToken).safeApprove(_comet, type(uint256).max);
        /// For depositor to pull funds to deposit
        ERC20(baseToken).safeApprove(_depositor, type(uint256).max);
        /// To sell reward tokens
        ERC20(rewardToken).safeApprove(address(router), type(uint256).max);

        /// Set the needed variables for the Uni Swapper
        /// Base will be weth
        base = weth;
        /// UniV3 mainnet router
        router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        /// Set the min amount for the swapper to sell
        minAmountToSell = 1e10;

        /// Default to .3% pool for comp/eth and to .05% pool for eth/baseToken
        _setFees(3000, 500, _ethToAssetFee);

        /// Set default price feeds
        priceFeeds[baseToken] = comet.baseTokenPriceFeed();
        /// Default to COMP/USD
        priceFeeds[rewardToken] = 0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5;
        /// Default to given feed for asset
        priceFeeds[asset] = comet.getAssetInfoByAddress(asset).priceFeed;
    }

    /// ----------------- SETTERS -----------------

    /**
     * @notice Set the parameters for the strategy
     * @dev Updates multiple strategy parameters to optimize contract bytecode size.
     * Ensure `_warningLTVMultiplier` is less than 9000 and `_targetLTVMultiplier` is less than `_warningLTVMultiplier`
     * Can only be called by management
     * @param _targetLTVMultiplier Desired target loan-to-value multiplier
     * @param _warningLTVMultiplier Warning threshold for loan-to-value multiplier
     * @param _minToSell Minimum amount to sell
     * @param _slippage Allowed slippage percentage
     * @param _preventDebtRepayment Bool to prevent debt repayment
     * @param _maxGasPriceToTend Maximum gas price for the tend operation
     */
    function setStrategyParams(
        uint16 _targetLTVMultiplier,
        uint16 _warningLTVMultiplier,
        uint256 _minToSell,
        uint256 _slippage,
        bool _preventDebtRepayment,
        uint256 _maxGasPriceToTend
    ) external onlyManagement {
        require(_warningLTVMultiplier <= 9_000 && _targetLTVMultiplier < _warningLTVMultiplier);
        targetLTVMultiplier = _targetLTVMultiplier;
        warningLTVMultiplier = _warningLTVMultiplier;
        minAmountToSell = _minToSell;
        require(_slippage < MAX_BPS, "slippage");
        preventDebtRepayment = _preventDebtRepayment;
        maxGasPriceToTend = _maxGasPriceToTend;
    }

    /**
     * @notice Set the price feed for a given token
     * @dev Updates the price feed for the specified token after a revert check
     * Can only be called by management
     * @param _token Address of the token for which to set the price feed
     * @param _priceFeed Address of the price feed contract
     */
    function setPriceFeed(address _token, address _priceFeed) external onlyManagement {
        comet.getPrice(_priceFeed);
        priceFeeds[_token] = _priceFeed;
    }

    /**
     * @notice Set the fees for different token swaps
     * @dev Configures fees for token swaps and can only be called by management
     * @param _rewardToEthFee Fee for swapping reward tokens to ETH
     * @param _ethToBaseFee Fee for swapping ETH to base token
     * @param _ethToAssetFee Fee for swapping ETH to asset token
     */
    function setFees(uint24 _rewardToEthFee, uint24 _ethToBaseFee, uint24 _ethToAssetFee) external onlyManagement {
        _setFees(_rewardToEthFee, _ethToBaseFee, _ethToAssetFee);
    }

    /**
     * @notice Internal function to set the fees for token swaps involving `weth`
     * @dev Sets the swap fees for rewardToken to WETH, baseToken to WETH, and asset to WETH
     * @param _rewardToEthFee Fee for swapping reward tokens to WETH
     * @param _ethToBaseFee Fee for swapping ETH to base token
     * @param _ethToAssetFee Fee for swapping ETH to asset token
     */
    function _setFees(uint24 _rewardToEthFee, uint24 _ethToBaseFee, uint24 _ethToAssetFee) internal {
        address _weth = base;
        _setUniFees(rewardToken, _weth, _rewardToEthFee);
        _setUniFees(baseToken, _weth, _ethToBaseFee);
        _setUniFees(asset, _weth, _ethToAssetFee);
    }

    /**
     * @notice Swap the base token between `asset` and `weth`
     * @dev This can be used for management to change which pool to trade reward tokens.
     */
    function swapBase() external onlyManagement {
        base = base == asset ? weth : asset;
    }

    /*///////////////////////////////////////////////
                NEEDED TO BE OVERRIDEN BY STRATEGIST
    ///////////////////////////////////////////////*/

    /**
     * @dev Should deploy up to '_amount' of 'asset' in the yield source.
     *
     * This function is called at the end of a {deposit} or {mint}
     * call. Meaning that unless a whitelist is implemented it will
     * be entirely permsionless and thus can be sandwhiched or otherwise
     * manipulated.
     *
     * @param _amount The amount of 'asset' that the strategy should attemppt
     * to deposit in the yield source.
     */
    function _deployFunds(uint256 _amount) internal override {
        _leveragePosition(_amount);
    }

    /**
     * @dev Will attempt to free the '_amount' of 'asset'.
     *
     * The amount of 'asset' that is already loose has already
     * been accounted for.
     *
     * This function is called during {withdraw} and {redeem} calls.
     * Meaning that unless a whitelist is implemented it will be
     * entirely permsionless and thus can be sandwhiched or otherwise
     * manipulated.
     *
     * Should not rely on asset.balanceOf(address(this)) calls other than
     * for diff accounting puroposes.
     *
     * Any difference between `_amount` and what is actually freed will be
     * counted as a loss and passed on to the withdrawer. This means
     * care should be taken in times of illiquidity. It may be better to revert
     * if withdraws are simply illiquid so not to realize incorrect losses.
     *
     * @param _amount, The amount of 'asset' to be freed.
     */
    function _freeFunds(uint256 _amount) internal override {
        _liquidatePosition(_amount);
    }

    /**
     * @dev Internal function to harvest all rewards, redeploy any idle
     * funds and return an accurate accounting of all funds currently
     * held by the Strategy.
     *
     * This should do any needed harvesting, rewards selling, accrual,
     * redepositing etc. to get the most accurate view of current assets.
     *
     * NOTE: All applicable assets including loose assets should be
     * accounted for in this function.
     *
     * Care should be taken when relying on oracles or swap values rather
     * than actual amounts as all Strategy profit/loss accounting will
     * be done based on this returned value.
     *
     * This can still be called post a shutdown, a strategist can check
     * `TokenizedStrategy.isShutdown()` to decide if funds should be
     * redeployed or simply realize any profits/losses.
     *
     * @return _totalAssets A trusted and accurate account for the total
     * amount of 'asset' the strategy currently holds including idle funds.
     */
    function _harvestAndReport() internal override returns (uint256 _totalAssets) {
        if (!TokenizedStrategy.isShutdown()) {
            /// 1. claim rewards, 2. even baseToken deposits and borrows 3. sell remainder of rewards to asset
            /// This will accrue this account as well as the depositor so all future calls are accurate
            _claimAndSellRewards();

            /// Leverage all the asset we have or up to the supply cap
            /// We want check our leverage even if balance of asset is 0
            _leveragePosition(Math.min(balanceOfAsset(), availableDepositLimit(address(this))));
        } else {
            /// Accrue the balances of both contracts for balances
            comet.accrueAccount(address(this));
            comet.accrueAccount(address(depositor));
        }

        /// Base token owed should be 0 here but we count it just in case
        _totalAssets = balanceOfAsset() + balanceOfCollateral() - _baseTokenOwedInAsset();

        /// Health check the amount to report
        _executeHealthCheck(_totalAssets);
    }

    /*///////////////////////////////////////////////
                    OPTIONAL TO OVERRIDE BY STRATEGIST
    ///////////////////////////////////////////////*/

    /**
     * @dev Optional function for strategist to override that can
     *  be called in between reports.
     *
     * If '_tend' is used tendTrigger() will also need to be overridden.
     *
     * This call can only be called by a persionned role so may be
     * through protected relays.
     *
     * This can be used to harvest and compound rewards, deposit idle funds,
     * perform needed poisition maintence or anything else that doesn't need
     * a full report for.
     *
     *   EX: A strategy that can not deposit funds without getting
     *       sandwhiched can use the tend when a certain threshold
     *       of idle to totalAssets has been reached.
     *
     * The TokenizedStrategy contract will do all needed debt and idle updates
     * after this has finished and will have no effect on PPS of the strategy
     * till report() is called.
     *
     * @param _totalIdle The current amount of idle funds that are available to deploy.
     */
    function _tend(uint256 _totalIdle) internal override {
        /// Accrue account for accurate balances
        comet.accrueAccount(address(this));

        /// If the cost to borrow > rewards rate we will pull out all funds to not report a loss
        if (getNetBorrowApr(0) > getNetRewardApr(0)) {
            /// Liquidate everything so not to report a loss
            _liquidatePosition(balanceOfCollateral());
            /// Return since we dont asset to do anything else
            return;
        }

        /// Else we need to either adjust LTV up or down.
        _leveragePosition(Math.min(_totalIdle, availableDepositLimit(address(this))));
    }

    /**
     * @notice Returns wether or not tend() should be called by a keeper.
     * @dev Optional trigger to override if tend() will be used by the strategy.
     * This must be implemented if the strategy hopes to invoke _tend().
     *
     * @return . Should return true if tend() should be called by keeper or false if not.
     */
    function tendTrigger() public view override returns (bool) {
        if (comet.isSupplyPaused() || comet.isWithdrawPaused()) return false;

        /// If we are in danger of being liquidated tend no matter what
        if (comet.isLiquidatable(address(this))) return true;

        /// We adjust position if:
        /// 1. LTV ratios are not in the HEALTHY range (either we take on more debt or repay debt)
        /// 2. Costs are acceptable
        uint256 collateralInUsd = _toUsd(balanceOfCollateral(), asset);
        uint256 debtInUsd = _toUsd(balanceOfDebt(), baseToken);
        uint256 currentLTV = (debtInUsd * 1e18) / collateralInUsd;
        uint256 targetLTV = _getTargetLTV();

        /// Check if we are over our warning LTV
        if (currentLTV > _getWarningLTV()) {
            /// We have a higher tolerance for gas cost here since we are closer to liquidation
            return _isBaseFeeAcceptable();
        }

        /// If Borrowing costs are to high.
        if (getNetBorrowApr(0) > getNetRewardApr(0)) {
            /// Tend if we are still levered and base fee is acceptable
            return currentLTV != 0 ? _isBaseFeeAcceptable() : false;

            /// If we are lower than our target. (we need a 10% (1000bps) difference)
        } else if ((currentLTV < targetLTV && targetLTV - currentLTV > 1e17)) {
            /// Make sure the increase in debt would keep borrwing costs healthy
            uint256 targetDebtUsd = (collateralInUsd * targetLTV) / 1e18;

            uint256 amountToBorrowUsd;
            unchecked {
                amountToBorrowUsd = targetDebtUsd - debtInUsd;
                /// Safe bc we checked ratios
            }

            /// cCnvert to BaseToken
            uint256 amountToBorrowBT = _fromUsd(amountToBorrowUsd, baseToken);

            /// We want to make sure that the reward apr > borrow apr so we dont reprot a loss
            /// Borrowing will cause the borrow apr to go up and the rewards apr to go down
            if (getNetBorrowApr(amountToBorrowBT) < getNetRewardApr(amountToBorrowBT)) {
                /// Borrowing costs are healthy and WE NEED TO TAKE ON MORE DEBT
                return _isBaseFeeAcceptable();
            }
        }

        return false;
    }

    /**
     * @notice Gets the max amount of `asset` that an adress can deposit.
     * @dev Defaults to an unlimited amount for any address. But can
     * be overriden by strategists.
     *
     * This function will be called before any deposit or mints to enforce
     * any limits desired by the strategist. This can be used for either a
     * traditional deposit limit or for implementing a whitelist etc.
     *
     *   EX:
     *      if(isAllowed[_owner]) return super.availableDepositLimit(_owner);
     *
     * This does not need to take into account any conversion rates
     * from shares to assets. But should know that any non max uint256
     * amounts may be converted to shares. So it is recommended to keep
     * custom amounts low enough as not to cause overflow when multiplied
     * by `totalSupply`.
     *
     * @param . The address that is depositing into the strategy.
     * @return . The avialable amount the `_owner` can deposit in terms of `asset`
     */
    function availableDepositLimit(address /*_owner*/ ) public view override returns (uint256) {
        /// We need to be able to both supply and withdraw on deposits.
        if (comet.isSupplyPaused() || comet.isWithdrawPaused()) return 0;

        return uint256(comet.getAssetInfoByAddress(asset).supplyCap - comet.totalsCollateral(asset).totalSupplyAsset);
    }

    /**
     * @notice Gets the max amount of `asset` that can be withdrawn.
     * @dev Defaults to an unlimited amount for any address. But can
     * be overriden by strategists.
     *
     * This function will be called before any withdraw or redeem to enforce
     * any limits desired by the strategist. This can be used for illiquid
     * or sandwhichable strategies. It should never be lower than `totalIdle`.
     *
     *   EX:
     *       return TokenIzedStrategy.totalIdle();
     *
     * This does not need to take into account the `_owner`'s share balance
     * or conversion rates from shares to assets.
     *
     * @param . The address that is withdrawing from the strategy.
     * @return . The avialable amount that can be withdrawn in terms of `asset`
     */
    function availableWithdrawLimit(address /*_owner*/ ) public view override returns (uint256) {
        /// Default liquidity is the balance of base token
        uint256 liquidity = balanceOfCollateral();

        /// If we can't withdraw or supply, set liquidity = 0.
        if (comet.isSupplyPaused() || comet.isWithdrawPaused()) {
            liquidity = 0;

            /// If there is not enough liquidity to pay back our full debt.
        } else if (ERC20(baseToken).balanceOf(address(comet)) < balanceOfDebt()) {
            /// Adjust liquidity based on withdrawing the full amount of debt.
            unchecked {
                liquidity = (
                    (_fromUsd(_toUsd(ERC20(baseToken).balanceOf(address(comet)), baseToken), asset) * MAX_BPS)
                        / _getTargetLTV()
                ) - 1;
                /// Minus 1 for rounding.
            }
        }

        return TokenizedStrategy.totalIdle() + liquidity;
    }

    /// ----------------- INTERNAL FUNCTIONS SUPPORT ----------------- \\

    /**
     * @notice Adjusts the leverage position of the strategy based on current and target Loan-to-Value (LTV) ratios.
     * @dev All debt and collateral calculations are done in USD terms. LTV values are represented in 1e18 format.
     * @param _amount The amount to be supplied to adjust the leverage position,
     */
    function _leveragePosition(uint256 _amount) internal {
        /// Supply the given amount to the strategy. This function internally checks for zero amounts.
        _supply(asset, _amount);

        uint256 collateralInUsd = _toUsd(balanceOfCollateral(), asset);
        uint256 debtInUsd = _toUsd(balanceOfDebt(), baseToken);
        uint256 currentLTV = (debtInUsd * 1e18) / collateralInUsd;
        uint256 targetLTV = _getTargetLTV();

        /// SUBOPTIMAL RATIO: If current LTV is below the target, potentially increase the debt.
        if (targetLTV > currentLTV) {
            uint256 targetDebtUsd = (collateralInUsd * targetLTV) / 1e18;
            uint256 amountToBorrowUsd;

            /// Safe subtraction as the ratios were checked earlier.
            unchecked {
                amountToBorrowUsd = targetDebtUsd - debtInUsd;
            }

            uint256 amountToBorrowBT = _fromUsd(amountToBorrowUsd, baseToken);

            /// Ensure borrowing doesn't lead to a loss by checking reward APR is higher than borrow APR.
            if (getNetBorrowApr(amountToBorrowBT) > getNetRewardApr(amountToBorrowBT)) {
                amountToBorrowBT = 0;
            }

            /// Ensure the debt is above a certain minimum threshold before proceeding.
            if (balanceOfDebt() + amountToBorrowBT > minThreshold) {
                _withdraw(baseToken, amountToBorrowBT);
            }

            /// UNHEALTHY RATIO: If current LTV is too high, reduce the debt.
        } else if (currentLTV > _getWarningLTV()) {
            uint256 targetDebtUsd = (targetLTV * collateralInUsd) / 1e18;
            _withdrawFromDepositor(_fromUsd(debtInUsd - targetDebtUsd, baseToken));
            _repayTokenDebt();
        }

        /// If there are any loose assets, deposit them back. @review when would that be the case?
        if (balanceOfBaseToken() > 0) {
            depositor.deposit();
        }
    }

    /**
     * @notice Liquidates the position to ensure the needed amount while maintaining healthy ratios.
     * @dev All debt, collateral, and needed amounts are calculated in USD. The needed amount is represented in the asset.
     * @param _needed The amount required in the asset.
     */
    function _liquidatePosition(uint256 _needed) internal {
        /// Cache current asset balance for withdrawal checks
        uint256 balance = balanceOfAsset();

        /// Update the account balances in the Comet protocol
        comet.accrueAccount(address(this));

        /// Repay BaseToken debt with the amount withdrawn from the vault to maintain healthy ratios
        _withdrawFromDepositor(_calculateAmountToRepay(_needed));
        _repayTokenDebt();

        /// Withdraw the required amount or the maximum possible while maintaining a healthy LTV
        _withdraw(asset, Math.min(_needed, _maxWithdrawal()));

        /// If the withdrawal wasn't enough, and there's remaining debt without available capital to repay it
        if (
            _needed > balanceOfAsset() - balance && balanceOfDebt() > 0 && balanceOfDepositor() == 0
                && !preventDebtRepayment
        ) {
            /// Repay debt by selling assets, which might result in losses but ensures full collateral release in wind downs
            _buyBaseToken();
            _repayTokenDebt();

            /// Attempt another withdrawal with the target LTV
            _withdraw(asset, _maxWithdrawal());
        }
    }

    /**
     * @notice Withdraws the required amount from the depositor, ensuring it doesn't exceed available balances.
     * @dev The function ensures that withdrawals only happen for amounts not already available and considers both the accrued comet balance and liquidity.
     * @param _amountBT The amount required in BaseToken.
     */
    function _withdrawFromDepositor(uint256 _amountBT) internal {
        /// Cache the current BaseToken balance
        uint256 balancePrior = balanceOfBaseToken();

        /// Adjust the withdrawal amount based on available balance
        _amountBT = balancePrior >= _amountBT ? 0 : _amountBT - balancePrior;
        if (_amountBT == 0) return;

        /// Ensure we do not withdraw more than the accrued balance in the Comet protocol
        _amountBT = Math.min(_amountBT, depositor.accruedCometBalance());

        /// Also ensure we do not exceed the available liquidity of the comet
        _amountBT = Math.min(_amountBT, ERC20(baseToken).balanceOf(address(comet)));

        depositor.withdraw(_amountBT);
    }

    /**
     * @notice Supplies a specified amount of an asset from this contract to Compound III.
     * @dev Can be used to supply both collateral and baseToken.
     * @param _asset The asset to be supplied.
     * @param amount The amount of the asset to supply.
     */
    function _supply(address _asset, uint256 amount) internal {
        if (amount == 0) return;
        comet.supply(_asset, amount);
    }

    /**
     * @notice Withdraws a specified amount of an asset from Compound III to this contract.
     * @dev Used for both collateral and borrowing baseToken.
     * @param _asset The asset to be withdrawn.
     * @param amount The amount of the asset to withdraw.
     */
    function _withdraw(address _asset, uint256 amount) internal {
        if (amount == 0) return;
        comet.withdraw(_asset, amount);
    }

    function _repayTokenDebt() internal {
        /// We cannot pay more than loose balance or more than we owe
        _supply(baseToken, Math.min(balanceOfBaseToken(), balanceOfDebt()));
    }

    function _maxWithdrawal() internal view returns (uint256) {
        uint256 collateral = balanceOfCollateral();
        uint256 debt = balanceOfDebt();

        /// If there is no debt we can withdraw everything
        if (debt == 0) return collateral;

        uint256 debtInUsd = _toUsd(balanceOfDebt(), baseToken);

        /// What we need to maintain a health LTV
        uint256 neededCollateral = _fromUsd((debtInUsd * 1e18) / _getTargetLTV(), asset);
        /// We need more collateral so we cant withdraw anything
        if (neededCollateral > collateral) {
            return 0;
        }

        /// Return the difference in terms of asset
        unchecked {
            return collateral - neededCollateral;
        }
    }

    function _calculateAmountToRepay(uint256 amount) internal view returns (uint256) {
        if (amount == 0) return 0;
        uint256 collateral = balanceOfCollateral();
        /// to unlock all collateral we must repay all the debt
        if (amount >= collateral) return balanceOfDebt();

        /// we check if the collateral that we are withdrawing leaves us in a risky range, we then take action
        uint256 newCollateralUsd = _toUsd(collateral - amount, asset);

        uint256 targetDebtUsd = (newCollateralUsd * _getTargetLTV()) / 1e18;
        uint256 targetDebt = _fromUsd(targetDebtUsd, baseToken);
        uint256 currentDebt = balanceOfDebt();
        /// Repay only if our target debt is lower than our current debt
        return targetDebt < currentDebt ? currentDebt - targetDebt : 0;
    }

    /// ----------------- INTERNAL CALCS -----------------

    /// Returns the _amount of _token in terms of USD, i.e 1e8
    function _toUsd(uint256 _amount, address _token) internal view returns (uint256) {
        if (_amount == 0) return _amount;
        /// usd price is returned as 1e8
        unchecked {
            return (_amount * getCompoundPrice(_token)) / (10 ** ERC20(_token).decimals());
        }
    }

    /// Returns the _amount of usd (1e8) in terms of _token
    function _fromUsd(uint256 _amount, address _token) internal view returns (uint256) {
        if (_amount == 0) return _amount;
        unchecked {
            return (_amount * (10 ** ERC20(_token).decimals())) / getCompoundPrice(_token);
        }
    }

    function balanceOfAsset() public view returns (uint256) {
        return ERC20(asset).balanceOf(address(this));
    }

    function balanceOfCollateral() public view returns (uint256) {
        return uint256(comet.userCollateral(address(this), asset).balance);
    }

    function balanceOfBaseToken() public view returns (uint256) {
        return ERC20(baseToken).balanceOf(address(this));
    }

    function balanceOfDepositor() public view returns (uint256) {
        return depositor.cometBalance();
    }

    function balanceOfDebt() public view returns (uint256) {
        return comet.borrowBalanceOf(address(this));
    }

    /// Returns the negative position of base token. i.e. borrowed - supplied
    /// if supplied is higher it will return 0
    function baseTokenOwedBalance() public view returns (uint256) {
        uint256 have = balanceOfDepositor() + balanceOfBaseToken();
        uint256 owe = balanceOfDebt();

        /// If they are the same or supply > debt return 0
        if (have >= owe) return 0;

        unchecked {
            return owe - have;
        }
    }

    function _baseTokenOwedInAsset() internal view returns (uint256 owed) {
        /// Only convert if the owed amount in base token is non-zero.
        uint256 owedInBase = baseTokenOwedBalance();
        if (owedInBase != 0) {
            owed = _fromUsd(_toUsd(owedInBase, baseToken), asset);
        }
    }

    function rewardsInAsset() public view returns (uint256) {
        /// underreport by 10% for safety @review why 10%
        return (_fromUsd(_toUsd(depositor.getRewardsOwed(), rewardToken), asset) * 9_000) / MAX_BPS;
    }

    /// We put the logic for these APR functions in the depositor contract to save byte code in the main strategy \\
    function getNetBorrowApr(uint256 newAmount) public view returns (uint256) {
        return depositor.getNetBorrowApr(newAmount);
    }

    function getNetRewardApr(uint256 newAmount) public view returns (uint256) {
        return depositor.getNetRewardApr(newAmount);
    }

    /// Get the liquidation collateral factor for an asset
    function getLiquidateCollateralFactor() public view returns (uint256) {
        return uint256(comet.getAssetInfoByAddress(asset).liquidateCollateralFactor);
    }

    /// Get the price feed address for an asset
    function getPriceFeedAddress(address _asset) internal view returns (address priceFeed) {
        priceFeed = priceFeeds[_asset];
        if (priceFeed == address(0)) {
            priceFeed = comet.getAssetInfoByAddress(_asset).priceFeed;
        }
    }

    /// Get the current price of an _asset from the protocol's persepctive
    function getCompoundPrice(address _asset) internal view returns (uint256 price) {
        price = comet.getPrice(getPriceFeedAddress(_asset));
        /// If weth is base token we need to scale response to e18
        if (price == 1e8 && _asset == weth) price = 1e18;
    }

    /// External function used to easisly calculate the current LTV of the strat
    function getCurrentLTV() external view returns (uint256) {
        unchecked {
            return (_toUsd(balanceOfDebt(), baseToken) * 1e18) / _toUsd(balanceOfCollateral(), asset);
        }
    }

    function _getTargetLTV() internal view returns (uint256) {
        unchecked {
            return (getLiquidateCollateralFactor() * targetLTVMultiplier) / MAX_BPS;
        }
    }

    function _getWarningLTV() internal view returns (uint256) {
        unchecked {
            return (getLiquidateCollateralFactor() * warningLTVMultiplier) / MAX_BPS;
        }
    }

    /// ----------------- HARVEST / TOKEN CONVERSIONS -----------------

    function claimRewards() external onlyKeepers {
        _claimRewards();
    }

    function _claimRewards() internal {
        rewardsContract.claim(address(comet), address(this), true);
        /// Pull rewards from depositor even if not incentivised to accrue the account
        depositor.claimRewards();
    }

    function _claimAndSellRewards() internal {
        _claimRewards();

        uint256 rewardTokenBalance;
        uint256 baseNeeded = baseTokenOwedBalance();

        if (baseNeeded > 0) {
            rewardTokenBalance = ERC20(rewardToken).balanceOf(address(this));
            /// Calculate the maximum amount of reward tokens we'd need to sell to get the required base token,
            /// taking into account potential slippage and any discrepancies from the oracle price, to avoid sandwich attacks.
            uint256 maxRewardToken =
                (_fromUsd(_toUsd(baseNeeded, baseToken), rewardToken) * (MAX_BPS + slippage)) / MAX_BPS;
            if (maxRewardToken < rewardTokenBalance) {
                /// If we have more than the maximum reward tokens required, swap the exact amount needed.
                _swapTo(rewardToken, baseToken, baseNeeded, maxRewardToken);
            } else {
                /// If we don't have enough reward tokens, swap all of them.
                _swapFrom(
                    rewardToken,
                    baseToken,
                    rewardTokenBalance,
                    _getAmountOut(rewardTokenBalance, rewardToken, baseToken)
                );
            }
        }

        rewardTokenBalance = ERC20(rewardToken).balanceOf(address(this));
        _swapFrom(rewardToken, asset, rewardTokenBalance, _getAmountOut(rewardTokenBalance, rewardToken, asset));
    }

    /**
     * @dev Buys the base token using the strategy's assets.
     * This function should only ever be called when withdrawing all funds from the strategy if there is debt left over.
     * Initially, it tries to sell rewards for the needed amount of base token, then it will swap assets.
     * Using this function in a standard withdrawal can cause it to be sandwiched, which is why rewards are used first.
     */
    function _buyBaseToken() internal {
        /// Try to obtain the required amount from rewards tokens before swapping assets and reporting losses.
        _claimAndSellRewards();

        uint256 baseStillOwed = baseTokenOwedBalance();
        /// Check if our debt balance is still greater than our base token balance.
        if (baseStillOwed > 0) {
            /// Account for slippage and the difference in the oracle price.
            /// Only small amounts should be swapped to ensure there's no substantial sandwich attack.
            uint256 maxAssetBalance =
                (_fromUsd(_toUsd(baseStillOwed, baseToken), asset) * (MAX_BPS + slippage)) / MAX_BPS;
            /// Amounts under 10 can lead to rounding errors from token conversions. Avoid swapping such small amounts.
            if (maxAssetBalance <= 10) return;

            _swapFrom(asset, baseToken, baseStillOwed, maxAssetBalance);
        }
    }

    function _getAmountOut(uint256 _amount, address _from, address _to) internal view returns (uint256) {
        if (_amount == 0) return 0;

        return (_fromUsd(_toUsd(_amount, _from), _to) * (MAX_BPS - slippage)) / MAX_BPS;
    }

    function _isBaseFeeAcceptable() internal view returns (bool) {
        return block.basefee <= maxGasPriceToTend;
    }

    /**
     * @dev Optional function for a strategist to override that will
     * allow management to manually withdraw deployed funds from the
     * yield source if a strategy is shutdown.
     *
     * This should attempt to free `_amount`, noting that `_amount` may
     * be more than is currently deployed.
     *
     * NOTE: This will not realize any profits or losses. A seperate
     * {report} will be needed in order to record any profit/loss. If
     * a report may need to be called after a shutdown it is important
     * to check if the strategy is shutdown during {_harvestAndReport}
     * so that it does not simply re-deploy all funds that had been freed.
     *
     * EX:
     *   if(freeAsset > 0 && !TokenizedStrategy.isShutdown()) {
     *       depositFunds...
     *    }
     *
     * @param _amount The amount of asset to attempt to free.
     */
    function _emergencyWithdraw(uint256 _amount) internal override {
        if (_amount > 0) {
            depositor.withdraw(_amount);
        }
        _repayTokenDebt();
    }
}

contract TokenizedCompV3LenderBorrowerFactory {
    //// @notice Address of the contract managing the strategies
    address public immutable managment;
    //// @notice Address where performance fees are sent
    address public immutable rewards;
    //// @notice Address of the keeper bot
    address public immutable keeper;
    //// @notice Address of the original depositor contract used for cloning
    address public immutable originalDepositor;

    /**
     * @notice Emitted when a new depositor and strategy are deployed
     * @param depositor Address of the deployed depositor contract
     * @param strategy Address of the deployed strategy contract
     */
    event Deployed(address indexed depositor, address indexed strategy);

    /**
     * @param _managment Address of the management contract
     * @param _rewards Address where performance fees will be sent
     * @param _keeper Address of the keeper bot
     */
    constructor(address _managment, address _rewards, address _keeper) {
        managment = _managment;
        rewards = _rewards;
        keeper = _keeper;
        /// Deploy an original depositor to clone
        originalDepositor = address(new Depositor());
    }

    function name() external pure returns (string memory) {
        return "Yearnv3-TokenizedCompV3LenderBorrowerFactory";
    }

    /**
     * @notice Deploys a new tokenized Compound v3 lender/borrower pair
     * @param _asset Underlying asset address
     * @param _name Name for strategy
     * @param _comet Comet observatory address
     * @param _ethToAssetFee Conversion fee for ETH to asset
     * @return depositor Address of the deployed depositor
     * @return strategy Address of the deployed strategy
     */
    function newCompV3LenderBorrower(
        address _asset,
        string memory _name,
        address _comet,
        uint24 _ethToAssetFee
    ) external returns (address, address) {
        address depositor = Depositor(originalDepositor).cloneDepositor(_comet);

        /// Need to give the address the correct interface
        IStrategyInterface strategy = IStrategyInterface(
            address(
                new Strategy(
                    _asset,
                    _name,
                    _comet,
                    _ethToAssetFee,
                    address(depositor)
                )
            )
        );

        /// Set strategy on depositor
        Depositor(depositor).setStrategy(address(strategy));

        /// Set the addresses
        strategy.setPerformanceFeeRecipient(rewards);
        strategy.setKeeper(keeper);
        strategy.setPendingManagement(managment);

        emit Deployed(depositor, address(strategy));
        return (depositor, address(strategy));
    }
}
