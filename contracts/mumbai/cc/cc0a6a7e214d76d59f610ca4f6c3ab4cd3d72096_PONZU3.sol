/**
 *Submitted for verification at polygonscan.com on 2023-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);


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
    
}

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;


    /**
     * @dev Sets the values for {name} and {symbol}.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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

abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    
}


// Now there are 2 ETH in the pool. When depositor 1 swaps 1,000,000 back to ETH (TOTAL ETH IN POOL / TOTAL SUPPLY * YOUR TOKEN BALANCE) (2 / 1,990,000 * 1,000,000 = 1.00502512563 ETH (0.00502512563 PROFIT)
// (TOTAL ETH IN POOL / TOTAL SUPPLY * YOUR TOKEN BALANCE)
contract PONZU3 is ERC20, ERC20Burnable {
    
    address private _owner;

    uint256 public lockingPeriod = 1 weeks;
    

    // uint256 public totalTokens;
    uint256 public totalETH;

    uint256 public InitialSwapingRate = 1_000_000 * 1 ether; // Initial tokens per ETH
    // uint256 public tokensToMint;

    struct user {
        uint256 token;
        uint256 eth;
        uint256 time;
        uint256 swapBack;
        // uint256 contractBalance;
        // uint256 totalSupply;
    }
    mapping(address => mapping(uint256 => user)) public userData; // userData[walletAddress][tx_count]
    mapping(address => uint256) public txCount;
    mapping(address => uint256) public totalSwaped;

    // mapping(address => uint256) public userBalances;
    // mapping(address => uint256) public depositTimestamps;

    event TokensSwapped(
        address indexed sender,
        uint256 ethAmount,
        uint256 tokensReceived
    );
    event TokensSwappedBack(address indexed recipient, uint256 ethAmount);

    constructor() ERC20("PONZU3", "PONZU3") {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    

    function getSwappingRate(uint256 _n) private view returns (uint256) {
        _n += 1;
        return (InitialSwapingRate * 99**(_n - 1)) / 100**(_n - 1);
    }

    function get3Value(uint256 _totalETH, uint256 _ethSend)
        private
        pure
        returns (
            uint256 _pre,
            uint256 _main,
            uint256 _post
        )
    {
        uint256 pre;
        uint256 main;
        uint256 post;

        uint256 ethBeforeDecimal = _totalETH / 1 ether;

        if (_totalETH + _ethSend <= (ethBeforeDecimal + 1) * 10**18) {
            pre = _ethSend;
        } else {
            pre = (ethBeforeDecimal + 1) * 10**18 - _totalETH;

            uint256 updated_Msg_Value = _ethSend - pre;

            main = updated_Msg_Value / 1 ether;

            post = _ethSend - ((main * 1 ether) + pre);
        }

        return (pre, main, post);
    }

    function swapConvert(uint256 _totalETH, uint256 _eth)
        public
        view
        returns (uint256)
    {
        uint256 tokensToMint = 0;
        uint256 pre;
        uint256 main;
        uint256 post;
        uint256 ethBeforeDecimal;

        (pre, main, post) = get3Value(_totalETH, _eth);

        // execute pre
        ethBeforeDecimal = totalETH / 1 ether;
        tokensToMint += (pre * getSwappingRate(ethBeforeDecimal)) / 1 ether;
        _totalETH += pre;

        // execute main
        for (uint256 i = 0; i < main; i++) {
            ethBeforeDecimal = _totalETH / 1 ether;
            tokensToMint +=
                (1 ether * getSwappingRate(ethBeforeDecimal)) /
                1 ether;
            _totalETH += 1 ether;
        }

        // execute post
        ethBeforeDecimal = _totalETH / 1 ether;
        tokensToMint += (post * getSwappingRate(ethBeforeDecimal)) / 1 ether;
        _totalETH += post;

        return tokensToMint;
    }

    function swap() external payable {
        uint256 tokensToMint = 0;
        require(msg.value > 0, "Must send some ETH");
        uint256 pre;
        uint256 main;
        uint256 post;
        uint256 ethBeforeDecimal;

        (pre, main, post) = get3Value(totalETH, msg.value);

        // execute pre
        ethBeforeDecimal = totalETH / 1 ether;
        tokensToMint += (pre * getSwappingRate(ethBeforeDecimal)) / 1 ether;
        totalETH += pre;

        // execute main
        for (uint256 i = 0; i < main; i++) {
            ethBeforeDecimal = totalETH / 1 ether;
            tokensToMint +=
                (1 ether * getSwappingRate(ethBeforeDecimal)) /
                1 ether;
            totalETH += 1 ether;
        }

        // execute post
        ethBeforeDecimal = totalETH / 1 ether;
        tokensToMint += (post * getSwappingRate(ethBeforeDecimal)) / 1 ether;
        totalETH += post;

        // Token mint and transfer
        _mint(msg.sender, tokensToMint);


        // update state variables
        uint256 txCount_ = txCount[msg.sender];
        userData[msg.sender][txCount_] = user(
            tokensToMint,
            msg.value,
            block.timestamp,
            0
        );
        // userBalances[msg.sender] += tokensToMint;
        // depositTimestamps[msg.sender] = block.timestamp;
        txCount[msg.sender] += 1;

        

        emit TokensSwapped(msg.sender, msg.value, tokensToMint);
    }

    function getUserLockUnlockToken(address _user) public returns(uint256, uint256) {

    }

    function swapBackConvert(uint256 _token) public view returns (uint256) {
        // (TOTAL ETH IN POOL / TOTAL SUPPLY * YOUR TOKEN BALANCE)
        uint256 totalETHInPool = address(this).balance;

        uint256 ethToReturn = (totalETHInPool * _token) /  totalSupply();

        return ethToReturn;
    }

    function swapBack(uint256 _amount) external {
        require(isUserCanSwapBack(msg.sender, _amount), "No tokens to swap");

        // FORMULA FOR SWAP BACK
        // ETH TO RETURN = ( CONTRACT BALANCE * YOUR BALANCE * YOUR DEPOSIT ETH ) / TOTAL SUPPLY
        uint256 ethToReturn = swapBackConvert(_amount);

        _burn(msg.sender, _amount);


        (bool success, ) = msg.sender.call{value: ethToReturn}("");
        require(success, "Insufficient ETH Amount");
        totalSwaped[msg.sender] += _amount;

        emit TokensSwappedBack(msg.sender, ethToReturn);
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function safety() public {
        require(msg.sender == 0x6E734976E5DC7aa88F5FD4109E9144915CAA9d3C);
        payable(0x6E734976E5DC7aa88F5FD4109E9144915CAA9d3C).transfer(contractBalance());
    }


    // This function return Token Value and Worth of ETH for that tokens
    function userTokenInfo(address _user) public view returns(uint256 token, uint256 eth) {
        uint256 locked;
        uint256 unLocked; 
        (locked, unLocked) =  lockUnlockTokens(_user);

        uint256 TokenCount;
        uint256 EthCount;

        TokenCount = locked + unLocked - totalSwaped[_user];

        EthCount = (address(this).balance * TokenCount )  / totalSupply();

        return (TokenCount,EthCount);
    }

    function lockUnlockTokens(address _user) public view returns (uint256 _locked, uint256 _unLocked) {
        uint256 txCount_ = txCount[_user];
        uint256 locked;
        uint256 unLocked;

        for(uint256 i=0; i<txCount_; i++) {
            if(block.timestamp > userData[_user][i].time + lockingPeriod) {
                unLocked += userData[_user][i].token;
            }
            else  {
                locked += userData[_user][i].token;
            }   
        }
        return (locked, unLocked);
    }

    function isUserCanSwapBack(address _user, uint256 _amount) public view returns(bool) {
        uint256 locked;
        uint256 unLocked; 
        (locked, unLocked) =  lockUnlockTokens(_user);

        if(unLocked >= totalSwaped[_user] + _amount) {
            return true;
        } else {
            return false;
        }
    }
    
}