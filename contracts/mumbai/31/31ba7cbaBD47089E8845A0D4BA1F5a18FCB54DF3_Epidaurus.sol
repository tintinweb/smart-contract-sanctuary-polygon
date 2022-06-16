/**
 *Submitted for verification at polygonscan.com on 2022-06-16
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

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

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

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

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
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
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract protectedOfferings is Ownable {
    address public ifoContract;
    uint256 upperLimit;
    uint256 lowerLimit;
    uint256 floorPrice = 8; // $0.0008

    mapping(address => uint256) records;

    function conditionsCheck(
        address to, 
        uint256 value) 
        public {
        require(
            ((value/10**18) * floorPrice <= upperLimit) &&
            ((value/10**18) >= lowerLimit)
        );
        records[to] += value;
    }

    function setIFOAddress(
        address _ifoContract) 
        public 
        onlyOwner {
        ifoContract = _ifoContract;
    }

    function setUpperLimit(
        uint256 _value) 
        public 
        onlyOwner {
        upperLimit = _value;
    }

    function setLowerLimit(
        uint256 _value) 
        public 
        onlyOwner {
        lowerLimit = _value;
    }

    function setFloorPrice(
        uint256 _value) 
        public 
        onlyOwner {
        floorPrice = _value;
    }
}

contract Epidaurus is ERC20, protectedOfferings {
    uint256 transferFee = 88; 
    uint256 charityFee = 42; 
    uint256 burnFee = 19; 
    uint256 rebaseFee = 19; 
    uint256 PUBLIC_LAUNCH = 1663700400; // September 21 2022
    address charityWallet;
    mapping(address => bool) trustedRecipients;
    mapping(address => bool) trustedSenders;

    constructor(address _charityWallet) ERC20("Codenamed", "CNMD") {
        charityWallet = _charityWallet;
    }

    function mint(uint256 amount)
    public
    //onlyOwner  
     {
        _mint(msg.sender, amount * 10**18);
    }

    function setCharityWallet(
        address _address
    )  
    public
    // onlyOwner
    {
        charityWallet = _address;
    }

    function addTrustedSenders(
        address _address)
        public
        // onlyOwner 
        {
        trustedSenders[_address] = true;
    }

    function addTrustedRecipients(
        address _address)
        public 
        // onlyOwner 
        {
        trustedRecipients[_address] = true;
    }

    function removeTrustedSenders(
        address _address)
        public
        // onlyOwner 
        {
        trustedSenders[_address] = false;
    }

    function removeTrustedRecipients(
        address _address) 
        public 
        // onlyOwner 
        {
        trustedRecipients[_address] = false;
    }

    function setTransferFee(
        uint256 newTransferFee) 
        public 
        // onlyOwner 
        {
        transferFee = newTransferFee;
    }

    function setCharityFee(
        uint256 newCharityFee) 
        public 
        // onlyOwner 
        {
        charityFee = newCharityFee;
    }

    function setBurnFee(
        uint256 newBurnFee) 
        public 
        // onlyOwner 
        {
        burnFee = newBurnFee;
    }

    function setRebaseFee(
        uint256 newRebaseFee) 
        public 
        // onlyOwner 
        {
        rebaseFee = newRebaseFee;
    }

    function airdrop(
        address recipient,
        uint256 _amount)
        public
        // onlyOwner
        {
        super._transfer(address(this), recipient, _amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal 
    virtual override{ 
        require(
            trustedSenders[msg.sender] || block.timestamp >= PUBLIC_LAUNCH,
            "Either you are not allowed or launch isn't public yet."
        );   
    }

    // @notice Conditions that are executed after the tokens are transferred.
    // This function after transferring the amount to the recipient, deducts some fee.
    // Transfer that fees back to the smart contract.
    // Fee calculations are done and sent to the relevant addresses.
    // Rebase and Airdrops are the remaining balance in the smart contract after that.
    // @params amount The amount that is being transferred between addresses.
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._afterTokenTransfer(from, to, amount);

        if (!trustedSenders[msg.sender]){

            uint256 feeAmount = (amount * transferFee) / 10000;
            uint256 charityAmount = (amount * charityFee) / 10000;
            uint256 burnAmount =  (amount * burnFee) / 10000;
            address receiver = to;
            uint256 ReceiverBalance = _balances[receiver];
           
            unchecked {
                _balances[receiver] = ReceiverBalance - feeAmount;
            }
            _balances[address(this)] += feeAmount;
            emit Transfer(address(this), receiver, feeAmount);

            unchecked {
                _balances[address(this)] -=charityAmount;
            }
            _balances[charityWallet] += charityAmount;

            emit Transfer(address(this), receiver, feeAmount);

            unchecked {
                _balances[address(this)] -= burnAmount;
            }
            _totalSupply -= burnAmount;
            emit Transfer(address(this), address(0), burnAmount);

        }
    }
}