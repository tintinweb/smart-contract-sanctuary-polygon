/**
 *Submitted for verification at polygonscan.com on 2023-07-06
*/

// File: contracts/MultiSig.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 *Submitted for verification at BscScan.com on 2023-03-24
 */

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
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
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

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

contract MultiSig {
    uint256 tokenAmount;
    string public title;

    struct Transaction {
        uint256 txId;
        address token;
        address destination;
        uint256 value;
        bool executed;
    }
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    mapping(IERC20 => bool) public isToken;
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;
    uint256 public MAX_OWNER_COUNT = 50;
    IERC20[] tokens;
    address public admin;
    /*
     *  Events
     */
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Deposit(address indexed token, address indexed sender, uint256 value);
    event RequirementChange(uint256 required);

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner], "Not, one of the owner");
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(transactions[transactionId].destination != address(0));
        _;
    }

    modifier confirmed(uint256 transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint256 transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }

    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        require(
            ownerCount <= MAX_OWNER_COUNT &&
                _required <= ownerCount &&
                _required != 0 &&
                ownerCount != 0,
            "Required length exceeds balance"
        );
        _;
    }

    constructor(
        string memory _title,
        address[] memory _owners,
        uint256 _required,
        uint256 _tokenAmount
    ) validRequirement(_owners.length, _required) {
        for (uint256 i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0));
            isOwner[_owners[i]] = true;
        }
        title = _title;
        owners = _owners;
        required = _required;
        tokenAmount = _tokenAmount;
        admin = tx.origin;
    }

    // {Add Tokens}
    function addTokens(IERC20 _token) external {
        require(msg.sender == admin, "Only the admin can add Tokens");
        require(!isToken[_token], "Token Already Added");
        require(
            tokens.length != tokenAmount,
            "You have added the maximum amount of tokens"
        );
        tokens.push(_token);
        isToken[_token] = true;
    }

    //{Fund Contracts}
    function fundContractTokens(IERC20 _token, uint256 _amount)
        external
        ownerExists(msg.sender)
    {
        require(isToken[_token], "Invalid Token");
        _token.transferFrom(msg.sender, address(this), _amount);
        emit Deposit(address(_token), msg.sender, _amount);
    }

    receive() external payable {
        require(msg.value > 0, "Send some eth");
        emit Deposit(address(0), msg.sender, msg.value);
    }

    function fundContract() external payable {
        require(msg.value > 0, "Send some eth");
        emit Deposit(address(0), msg.sender, msg.value);
    }

    // {Confirm Transaction}
    function confirmTransaction(uint256 transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    // {Revoke  Transaction}
    function revokeConfirmation(uint256 transactionId)
        external
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    // {Execute  Transaction}
    function executeTransaction(uint256 transactionId)
        internal
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (txn.token == address(0)) {
                require(
                    address(this).balance >= txn.value,
                    "Not enough Balance"
                );

                (bool os, ) = payable(txn.destination).call{value: txn.value}(
                    ""
                );
                require(os, "Execution Failed");
            } else {
                require(
                    IERC20(txn.token).balanceOf(address(this)) >= txn.value,
                    "Not enough tokens"
                );
                IERC20(txn.token).transfer(txn.destination, txn.value);
            }
            emit Execution(transactionId);
        }
    }

    function isConfirmed(uint256 transactionId)
        public
        view
        returns (bool success)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) count += 1;
            if (count == required) return true;
        }
    }

    // {Transactions}

    function addTransaction(
        address _token,
        address destination,
        uint256 value
    )
        external
        notNull(destination)
        // notNull(destination)
        ownerExists(msg.sender)
        returns (uint256 transactionId)
    {
        if (_token == address(0)) {
            require(address(this).balance >= value, "Not enough balance");
        } else {
            require(
                IERC20(_token).balanceOf(address(this)) >= value,
                "Not enough tokens"
            );
        }
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            txId: transactionId,
            token: _token,
            destination: destination,
            value: value,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    function getConfirmationCount(uint256 transactionId)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) count += 1;
    }

    function getTransactionCount(bool pending, bool executed)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < transactionCount; i++)
            if (
                (pending && !transactions[i].executed) ||
                (executed && transactions[i].executed)
            ) count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getConfirmations(uint256 transactionId)
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) _confirmations[i] = confirmationsTemp[i];
    }

    // it will return the executed transactions
    function getExecutedTransactionIds()
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < transactionCount; i++) {
            if (transactions[i].executed) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }
        uint256[] memory _transactionIds = new uint256[](count);
        for (i = 0; i < count; i++) {
            _transactionIds[i] = transactionIdsTemp[i];
        }
        return _transactionIds;
    }

    //it will return all the pending transactions
    function getPendingTransactionIds() public view returns (uint256[] memory) {
        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < transactionCount; i++) {
            if (!transactions[i].executed) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }
        uint256[] memory _transactionIds = new uint256[](count);
        for (i = 0; i < count; i++) {
            _transactionIds[i] = transactionIdsTemp[i];
        }
        return _transactionIds;
    }


    // {Get Balance Of ERC20 Token}
    function getTokenBalance(IERC20 _token) external view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    // {Get Balance Of Native Contract}
    function getCoinBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // {returns Tokens}
    function getTokens() external view returns (IERC20[] memory) {
        return tokens;
    }

    function changeAdmin(address newAdmin) external {
        require(msg.sender == admin, "Only admin");
        require(isOwner[newAdmin], "New admin is not an owner");
        admin = newAdmin;
    }

    //remove the token from the list
    function removeToken(IERC20 _token) external {
        require(msg.sender == admin, "Only admin");
        require(isToken[_token], "Token Already removed");
        isToken[_token] = false;
        for (uint256 i; i < tokens.length; i++) {
            if (tokens[i] == _token) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
    }
}

contract Factory {
    event MultiSigInstantiation(address sender, address instantiation);

    mapping(address => bool) public isMultiSig;
    mapping(address => address[]) public multiSigs;

    constructor() {}

    function returnMultiSigs(address _addr)
        public
        view
        returns (address[] memory)
    {
        return multiSigs[_addr];
    }

    function getInstantiationCount(address creator)
        public
        view
        returns (uint256)
    {
        return multiSigs[creator].length;
    }

    function register(address instantiation) internal {
        isMultiSig[instantiation] = true;
        multiSigs[msg.sender].push(instantiation);
        emit MultiSigInstantiation(msg.sender, instantiation);
    }
}

contract MultiSigFactory is Factory, Ownable {
    struct multiSig {
        address inMultiSigs;
        uint256 timeStamp;
    }
    uint256 public s1 = 0.001 ether;
    uint256 public s2 = 0.002 ether;
    uint256 public s3 = 0.003 ether;
    uint256 public s1Token = 0.0001 ether;
    uint256 public s2Token = 0.0002 ether;
    uint256 public s3Token = 0.0003 ether;
    uint256 public s1TokenAmount = 5;
    uint256 public s2TokenAmount = 10;
    uint256 public s3TokenAmount = 15;
    uint256 public _sub1Owners = 3;
    uint256 public _sub2Owners = 5;
    uint256 public _sub3Owners = 10;
    uint256 public free1Token = 100 ether;
    uint256 public free2Token = 200 ether;
    uint256 public free3Token = 300 ether;
    IERC20 public token;

    mapping(uint256 => address[]) totalAddresses;
    mapping(address => bool) public isOneOfOwner;
    mapping(address => multiSig[]) multiSigDetail;
    mapping(address => bool) public freeSubscribed;

    constructor(IERC20 _token) {
        token = _token;
    }

    function totalAddressess() public view returns (address[] memory) {
        return totalAddresses[0];
    }

    function getInMultiSigs(address _addr)
        public
        view
        returns (multiSig[] memory)
    {
        return multiSigDetail[_addr];
    }

    function createMultiSig(
        string memory _title,
        address[] memory _owners,
        uint256 _required,
        uint256 _subscription,
        bool _token
    ) public payable returns (MultiSig wallet) {
        require(
            _subscription >= 1 && _subscription <= 3,
            "Invalid subscription"
        );

        if (_subscription == 1) {
            require(_owners.length + 1 <= _sub1Owners, "Max owners reach");
        } else if (_subscription == 2) {
            require(_owners.length + 1 <= _sub2Owners, "Max owners reach");
        } else {
            require(_owners.length + 1 <= _sub3Owners, "Max owners reach");
        }
        // Add msg.sender to the _owners array
        address[] memory newOwners = new address[](_owners.length + 1);
        for (uint256 i = 0; i < _owners.length; i++) {
            newOwners[i] = _owners[i];
        }
       
        newOwners[_owners.length] = msg.sender;

        address[] memory temp = totalAddresses[0];
        bool tempCheck;
        for (uint256 i = 0; i < temp.length; i++) {
            if (msg.sender == temp[i]) {
                tempCheck = true;
            }
        }
        if (tempCheck == false) {
            totalAddresses[0].push(msg.sender);
        }

        for (uint256 i = 0; i < newOwners.length; i++) {
            if (isOneOfOwner[newOwners[i]] == false)
                isOneOfOwner[newOwners[i]] = true;
        }
        bool free;
        if (!freeSubscribed[msg.sender]) {
            uint256 balance = token.balanceOf(msg.sender);
            if (balance >= free1Token && balance < free2Token) {
                if (_subscription == 1) {
                    free = true;
                }
            } else if (balance >= free2Token && balance < free3Token) {
                if (_subscription == 1 || _subscription == 2) {
                    free = true;
                }
            } else if (balance >= free3Token) {
                free = true;
            }
        }
        if (free) {
            freeSubscribed[msg.sender] = true;
        }

        uint256 price;

        if (_subscription == 1) {
            _token ? price = s1Token : price = s1;
        } else if (_subscription == 2) {
            _token ? price = s2Token : price = s2;
        } else {
            _token ? price = s3Token : price = s3;
        }
        if (!free) {
            if (_token) {
                token.transferFrom(msg.sender, owner(), price);
            }
        }
        if (!_token) {
            require(msg.value >= price, "NOt correct amount for subscription");
            payable(owner()).transfer(price);
        }

        if (_subscription == 1)
            wallet = new MultiSig(_title, newOwners, _required, s1TokenAmount);
        else if (_subscription == 2)
            wallet = new MultiSig(_title, newOwners, _required, s2TokenAmount);
        else wallet = new MultiSig(_title, newOwners, _required, s3TokenAmount);
        register(address(wallet));

        for (uint256 i = 0; i < newOwners.length; i++) {
            multiSigDetail[newOwners[i]].push(
                multiSig(address(wallet), block.timestamp)
            );
        }
    }

    // update Token
    function updateToken(IERC20 _token) external onlyOwner {
        token = _token;
    }

    //to change subscription owners
    function changeSub1Owners(uint256 newSub1Owners) external onlyOwner {
        _sub1Owners = newSub1Owners;
    }

    function changeSub2Owners(uint256 newSub2Owners) external onlyOwner {
        _sub1Owners = newSub2Owners;
    }

    function changeSub3Owners(uint256 newSub3Owners) external onlyOwner {
        _sub1Owners = newSub3Owners;
    }

    //update the free subscription requirements
    function changeFree1Token(uint256 _newFree1Token) external onlyOwner {
        free1Token = _newFree1Token;
    }

    function changeFree2Token(uint256 _newFree2Token) external onlyOwner {
        free2Token = _newFree2Token;
    }

    function changeFree3Token(uint256 _newFree3Token) external onlyOwner {
        free3Token = _newFree3Token;
    }

    //update Prices

    function s1Price(uint256 _s1) external onlyOwner {
        s1 = _s1;
    }

    function s2Price(uint256 _s2) external onlyOwner {
        s2 = _s2;
    }

    function s3Price(uint256 _s3) external onlyOwner {
        s3 = _s3;
    }

    function s1TokenPrice(uint256 _s1Token) external onlyOwner {
        s1Token = _s1Token;
    }

    function s2TokenPrice(uint256 _s2Token) external onlyOwner {
        s2Token = _s2Token;
    }

    function s3TokenPrice(uint256 _s3Token) external onlyOwner {
        s3Token = _s3Token;
    }

    //update the token Amounts
    function setS1TokenAmount(uint256 _s1TokenAmount) external onlyOwner {
        s1TokenAmount = _s1TokenAmount;
    }

    function setS2TokenAmount(uint256 _s2TokenAmount) external onlyOwner {
        s2TokenAmount = _s2TokenAmount;
    }

    function setS3TokenAmount(uint256 _s3TokenAmount) external onlyOwner {
        s3TokenAmount = _s3TokenAmount;
    }
}