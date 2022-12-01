/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



pragma solidity >=0.7.0 <0.9.0;

contract ERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

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

        // emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        // emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function mint(address _account, uint256 _amount) external {
        _mint(_account, _amount);
    }

    //  function transferOut (address addr, uint  _amount)external onlyOwner  {

    //     uint bal = balanceOf(address(this));
    //     require (bal >= _amount , "You cant send more than balance");
    //     _transfer(address(this), addr , _amount );
    // }

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

        // emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        // emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/budgetItem.sol


pragma solidity ^0.8.9;


contract AnnualBudget {
    uint256 public unlockTime;
    uint256 public budgetCount = 0;
    uint256 public initialBudgetFunds;
    address payable public owner;
    ERC20 public maticContractAddress;

    event ItemRemoved(uint256 indexed ID);

    event Withdrawal(uint256 amount, uint256 when);

    error transferFailed();
    error amountEqualZero();
    error notOwner();
    error notYetTime();
    error doesNotExist();

    event BudgetCreated(
        uint256 indexed ID,
        uint256 indexed amount,
        string indexed content,
        bool created
    );

    struct budgetItems {
        uint256 ID;
        uint256 maticAmount;
        string item;
        bool created;
    }

    budgetItems[] myBudgetList;

    mapping(uint256 => budgetItems) public Budgets;
    mapping(uint256 => bool) public removeItem;

    constructor(address _maticContractAddress, uint256 _unLockTime)  {
        require(block.timestamp < _unLockTime, "Not Yet Christmas");

        unlockTime = _unLockTime;
        maticContractAddress = ERC20(_maticContractAddress);
        owner = payable(msg.sender);
    
    }

    function createBudget(string memory _item, uint256 _maticAmount) public {
       
        if (Budgets[budgetCount].created == true) {
            revert("Item already created");
        }

        budgetItems memory itemOnlist = Budgets[budgetCount];
        itemOnlist = budgetItems(budgetCount, _maticAmount, _item, true);
        myBudgetList.push(itemOnlist);
        

        emit BudgetCreated(budgetCount, _maticAmount, _item, true);
        budgetCount++;
    }

    function myList() external view returns(budgetItems[] memory){
        return myBudgetList;
    } 

    function listItem(uint256 _ID) external view returns(budgetItems memory){
        return Budgets[_ID];
    }

    function balance() public view returns(uint256 contractBalance){
        return ERC20(maticContractAddress).balanceOf(address(this));
    }

    function removeItems(uint256 _ID) public {
        if (msg.sender == owner) {
            revert notOwner();
        }

        if (removeItem[_ID] == true) {
            revert doesNotExist();
        }

        emit ItemRemoved(_ID);
        delete Budgets[_ID];
    }

    function withdraw() public {
        if (block.timestamp <= unlockTime) 
        revert ("Not Yet Time");
        
        if (msg.sender != owner){
            revert ("Not Owner");
        
        } 
            

        uint256 amount = ERC20(maticContractAddress).balanceOf(address(this));

        if(amount == 0) revert amountEqualZero();

        emit Withdrawal(amount, block.timestamp);

        bool success = ERC20(maticContractAddress).transfer(owner, amount);
        if(!success) revert transferFailed();

    }

    function depositBudgetFund(uint256 amount) public payable {
        require(msg.sender != address(0), "Invalid Address");
        require(
            ERC20(maticContractAddress).balanceOf(msg.sender) > 0,
            "Insufficient matic balance"
        );

        if(amount == 0) revert amountEqualZero();

       bool success = ERC20(maticContractAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        if(!success) revert transferFailed();

        initialBudgetFunds += amount;
    }
}