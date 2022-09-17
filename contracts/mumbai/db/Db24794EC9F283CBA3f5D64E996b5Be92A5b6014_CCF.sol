/**
 *Submitted for verification at polygonscan.com on 2022-09-17
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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

// File: CFlip.sol


pragma solidity ^0.8.15;



contract CCF {
    mapping (address => uint) balance;
    address[30] PlayerOneAddress; 
    address[30] PlayerTwoAddress; 
    uint[30] PriceOfTable;  
    uint[30] CoinTypePlaced;
    uint[30] Winner;
    bool[30] GameStarted;

    uint private Interaction = 0;
    uint public Tax =6;
    bool public VsBotsActive=false;

    address constant ContractOwner = 0xa4087A999288B7866f31E8b5537721c92584dE97;
   // address constant BloodToken = 0x9c8919d6E97Be2B8B823FFfB699ef1cb3422C77F;
    address constant BloodToken = 0xC8b8F3e1E96bd357aa3b9F0eEc8C19F35dBe0ace;

    ERC20 tokenContract = ERC20(BloodToken);

    modifier onlyOwner {
        require(msg.sender == ContractOwner, "Ownable: You are not the owner");  //Require Contract Owner to have same  address to use function
        _;
    }



    function GetGameData() public view returns(bool[30] memory, uint[30] memory ,uint[30] memory,uint[30] memory, bytes memory, bytes memory)
    {
        return (GameStarted,PriceOfTable,CoinTypePlaced,Winner,abi.encodePacked(PlayerOneAddress),abi.encodePacked(PlayerTwoAddress));
    }



    function QueryInteraction() public view returns(uint)
    {
        return Interaction;
    }

    

    function SetBotActive(bool Active) public onlyOwner {
        VsBotsActive=Active;
    }


    function SetTax(uint NewTax) public onlyOwner {
        Tax=NewTax;
    }



    function QueryBalance(address CheckAddress) public view returns(uint)
    {
        return balance[CheckAddress];
    }




   function Approving(uint256 amount) external {
        tokenContract.approve(address(this), amount);
   }

       function ApprovingTest2(uint256 amount) external {
        tokenContract.approve(address(this), amount);
        _safeTransferFrom(tokenContract, msg.sender, address(this), amount);
        balance[msg.sender] += amount;
   }

    function deposit(uint256 amount) external {
        require(amount>0);
        require(
            tokenContract.allowance(msg.sender, address(this)) >= amount,
            "Token allowance too low"
        );

        _safeTransferFrom(tokenContract, msg.sender, address(this), amount);
       // ERC20 tokenContract = ERC20(BloodToken);
       // tokenContract.transferFrom(msg.sender, address(this), amount);
        //*
        //
        //ERC20 tokenContract = ERC20(BloodToken);
        balance[msg.sender] += amount;
    //    tokenContract.approve(address(this), amount);
        //tokenContract.allowance(msg.sender, address(this));
        //tokenContract.transferFrom(msg.sender, address(this), amount);
    }
    



    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint amount
    ) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }


    function approve(uint256 amount) external {
        require(amount>0);
        ERC20 tokenContract = ERC20(BloodToken);
        tokenContract.approve(address(this), amount);
    }





    function withdraw(uint256 amount) external {
        if (amount > balance[msg.sender]) {
            amount = balance[msg.sender];
        }
        balance[msg.sender] -= amount;
        ERC20 tokenContract = ERC20(BloodToken);
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, amount);
    }




    function PlayVsBot(uint GameID) public {
        require(VsBotsActive==true);
        require(balance[ContractOwner]>PriceOfTable[GameID]);
        require((balance[msg.sender] >= PriceOfTable[GameID]));
            //play Game        
            //Pick random number
            Interaction++;
            Winner[GameID]  = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  Interaction))) % 2;
            
            //Pay Tax   
            //Tax  // =6
            uint TaxToPay = PriceOfTable[GameID] / 100 * Tax;
            PlayerTwoAddress[GameID] = ContractOwner;

            //if random number is the player
            if(Winner[GameID] == CoinTypePlaced[GameID])
            {
                balance[ContractOwner] -= PriceOfTable[GameID];  //remove winning amount from contract
                balance[PlayerOneAddress[GameID]]+= (PriceOfTable[GameID]*2)-TaxToPay; 
            }
            else {        //otherwise pay out player 2 (player that joined)
                balance[ContractOwner] += PriceOfTable[GameID]-TaxToPay;
            }

            balance[ContractOwner] += TaxToPay;

            //Reset Game
            GameStarted[GameID] = false;
    }


    //Withdraw funds from contract
    function JoinGame(uint GameID) public {
            require((balance[msg.sender] >= PriceOfTable[GameID]));

            //play Game        
            //Pick random number
            Interaction++;
            Winner[GameID] = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  Interaction))) % 2;

            //Pay Tax   
            //Tax  // =6
            uint TaxToPay = PriceOfTable[GameID] / 100 * Tax;
            PlayerTwoAddress[GameID] = msg.sender;
            //if random number is the same as the coin selection of player 1, pay out to player 1
            if(Winner[GameID] == CoinTypePlaced[GameID])
            {
                balance[msg.sender] -= PriceOfTable[GameID];
                balance[PlayerOneAddress[GameID]]+= (PriceOfTable[GameID]*2)-TaxToPay; 
            }
            else {        //otherwise pay out player 2 (player that joined)
                balance[msg.sender] += PriceOfTable[GameID]-TaxToPay;
            }

            balance[ContractOwner] += TaxToPay;

            //Reset Game
            GameStarted[GameID] = false;
    }


    function CancelAllMyGames() public {
        for (uint i = 0; i < 30; i++) {
            if(GameStarted[i]==true && msg.sender == PlayerOneAddress[i])
            {
                balance[msg.sender] += PriceOfTable[i];  //Return Money
                GameStarted[i] = false;
                Interaction++;
            }
        }
    }

    //Withdraw funds from contract
    function JoinGame(uint GameID, uint GameIDTwo) public {
            require((balance[msg.sender] >= PriceOfTable[GameID]+PriceOfTable[GameIDTwo]));

            JoinGame(GameID);
            JoinGame(GameIDTwo);
    }

    //Withdraw funds from contract
    function JoinGame(uint GameID, uint GameIDTwo, uint GameIDThree) public {
            require((balance[msg.sender] >= PriceOfTable[GameID]+PriceOfTable[GameIDTwo]+PriceOfTable[GameIDThree]));

            JoinGame(GameID);
            JoinGame(GameIDTwo);
            JoinGame(GameIDThree);
    }

    //Withdraw funds from contract
    function JoinGame(uint GameID, uint GameIDTwo, uint GameIDThree, uint GameIDFour) public {
            require((balance[msg.sender] >= PriceOfTable[GameID]+PriceOfTable[GameIDTwo]+PriceOfTable[GameIDThree]+PriceOfTable[GameIDFour]));

            JoinGame(GameID);
            JoinGame(GameIDTwo);
            JoinGame(GameIDThree);
            JoinGame(GameIDFour);
    }

    //Withdraw funds from contract
    function JoinGame(uint GameID, uint GameIDTwo, uint GameIDThree, uint GameIDFour, uint GameIDFive) public {
            require((balance[msg.sender] >= PriceOfTable[GameID]+PriceOfTable[GameIDTwo]+PriceOfTable[GameIDThree]+PriceOfTable[GameIDFour]+PriceOfTable[GameIDFive]));

            JoinGame(GameID);
            JoinGame(GameIDTwo);
            JoinGame(GameIDThree);
            JoinGame(GameIDFour);
            JoinGame(GameIDFive);
    }




    function CancelGame(uint GameID) public{
        require(GameStarted[GameID]==true);
        require(msg.sender == PlayerOneAddress[GameID]);
        
        balance[msg.sender] += PriceOfTable[GameID];  //Return Money
        GameStarted[GameID] = false;
        Interaction++;
    }


    function CreateGame(uint amount, uint CoinType) public {
        require(balance[msg.sender] >= amount);
        require(amount > 0);

        for (uint i = 0; i < 30; i++) {
            if(GameStarted[i]==false)
            {
                balance[msg.sender] -= amount;
                GameStarted[i]=true;
                PlayerOneAddress[i]=msg.sender;
                CoinTypePlaced[i] = CoinType;
                PriceOfTable[i]=amount;
                Interaction++;
                Winner[i]=3;
                break;
            }
            
        }
    }
}