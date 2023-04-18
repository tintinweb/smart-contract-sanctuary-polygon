// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Authorizable is Ownable {
    mapping(address => bool) private _authorized;

    modifier onlyAuthorized() {
        require(
            _authorized[msg.sender] || owner() == msg.sender,
            "Authorizable: authorization error"
        );
        _;
    }

    function addAuthorized(address _toAdd) internal {
        require(
            _toAdd != address(0),
            "Authorizable: new owner is the zero address"
        );
        _authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) internal {
        require(
            _toRemove != address(0),
            "Authorizable: new owner is the zero address"
        );
        _authorized[_toRemove] = false;
    }

    function authorized(address _user) public view returns (bool) {
        return _authorized[_user] || owner() == _user;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

library Enterprise {
    uint256 constant MAX_LENGTH = 100;

    enum CompanyType {
        LLC,
        CC,
        SC,
        NP,
        OT
    }

    struct Info {
        string logoImg;
        string enterpriseName;
        string description;
        bool isRG;
        CompanyType companyType;
        address admin;
        string ipfs;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;
/**
____    __    ____  ______   .______      __       _______      _______ .__   __. .___________._______ .______     .______   .______      __       _______. _______ 
\   \  /  \  /   / /  __  \  |   _  \    |  |     |       \    |   ____||  \ |  | |           |   ____||   _  \    |   _  \  |   _  \    |  |     /       ||   ____|
 \   \/    \/   / |  |  |  | |  |_)  |   |  |     |  .--.  |   |  |__   |   \|  | `---|  |----|  |__   |  |_)  |   |  |_)  | |  |_)  |   |  |    |   (----`|  |__   
  \            /  |  |  |  | |      /    |  |     |  |  |  |   |   __|  |  . `  |     |  |    |   __|  |      /    |   ___/  |      /    |  |     \   \    |   __|  
   \    /\    /   |  `--'  | |  |\  \----|  `----.|  '--'  |   |  |____ |  |\   |     |  |    |  |____ |  |\  \----|  |      |  |\  \----|  | .----)   |   |  |____ 
    \__/  \__/     \______/  | _| `._____|_______||_______/    |_______||__| \__|     |__|    |_______|| _| `._____| _|      | _| `._____|__| |_______/    |_______|
 **/

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/Enterprise.sol";
import "./libs/Authorizable.sol";

contract WorldEnterprise is IERC20, Authorizable {
    using Counters for Counters.Counter;

    enum ProposalStatus {
        NONE,
        ACTIVE,
        CANCELLED,
        FAILED,
        PASSED
    }

    enum OrderStatus {
        NONE,
        ACTIVE,
        CANCELLED,
        CLOSED
    }

    enum OrderType {
        BUY,
        SELL
    }

    enum ProposalType {
        ADD,
        REMOVE,
        MINT
    }

    struct Proposal {
        uint256 id;
        address owner;
        uint256 amount;
        string commentUrl;
        uint256 startTime;
        uint256 endTime;
        uint256 yes;
        uint256 no;
        ProposalStatus status;
        ProposalType pType;
    }

    struct Order {
        uint256 id;
        address owner;
        uint256 amount;
        uint256 price;
        OrderType orderType;
        OrderStatus status;
    }

    Counters.Counter public proposalIndex;
    Counters.Counter public orderIndex;

    uint8 public decimals;

    // proposal delay time
    uint256 public proposalDelayTime;

    Enterprise.Info public info;

    /**
     * proposal list
     * @dev mapping(proposal id => Proposal)
     **/
    mapping(uint256 => Proposal) public proposals;

    /**
     * proposal indices of proposer
     * @dev mapping(proposer address => indices)
     * */
    mapping(address => uint256[]) public proposalIndices;

    /**
     * vote info list
     * @dev mapping(proposal id => poroposer => status)
     * */
    mapping(uint256 => mapping(address => bool)) public votes;

    /**
     * order list
     * @dev mapping(order id => Order)
     **/
    mapping(uint256 => Order) public orders;

    /**
     * order indices by owner
     * @dev mapping(owner => indices)
     * */
    mapping(address => uint256[]) public orderIndices;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _tokenHolders;

    string private _name;
    string private _symbol;

    event JoinWorldEnterprise(
        uint256 proposalIndex,
        address indexed proposer,
        uint256 amount,
        uint256 price,
        string commentUrl,
        uint256 startTime,
        uint256 endTime
    );
    event RequestAdminRole(
        uint256 proposalIndex,
        address indexed proposer,
        bool isAdd,
        uint256 startTime,
        uint256 endTime
    );
    event VoteYes(address indexed account, uint256 proposalIndex);
    event VoteNo(address indexed account, uint256 proposalIndex);
    event ExecutePassed(
        uint256 proposalIndex,
        address indexed proposer,
        uint256 amount
    );
    event ExecuteAdminAddPassed(uint256 proposalIndex, address indexed admin);
    event ExecuteAdminRemovePassed(
        uint256 proposalIndex,
        address indexed admin
    );
    event ExecuteFailed(uint256 proposalIndex);
    event CreateBuyOrder(
        uint256 orderIndex,
        address indexed owner,
        uint256 amount,
        uint256 price
    );
    event CreateSellOrder(
        uint256 orderIndex,
        address indexed owner,
        uint256 amount,
        uint256 price
    );
    event CloseOrder(uint256 orderId);
    event CancelOrder(uint256 orderId);
    event Withdraw(address indexed owner, address indexed to, uint256 amount);
    event WithdrawToken(
        address indexed token,
        address indexed owner,
        address indexed to,
        uint256 amount
    );
    event UpdateInfo(Enterprise.Info info);

    modifier checkInfo(Enterprise.Info memory info_) {
        require(
            bytes(info_.logoImg).length < Enterprise.MAX_LENGTH,
            "WorldEnterprise: Logo image url should be less than the max length"
        );
        require(
            bytes(info_.enterpriseName).length < Enterprise.MAX_LENGTH,
            "WorldEnterprise: Enterprise name should be less than the max length"
        );
        require(
            bytes(info_.ipfs).length < Enterprise.MAX_LENGTH,
            "WorldEnterprise: IPFS url should be less than the max length"
        );
        _;
    }

    constructor(
        address admin,
        address[] memory users,
        uint256[] memory shares,
        string memory name_,
        string memory symbol_,
        Enterprise.Info memory info_
    ) checkInfo(info_) {
        require(
            users.length > 0,
            "WorldEnterprise: Users length should be greater than the zero"
        );
        require(
            users.length == shares.length,
            "WorldEnterprise: Shares length should be equal with the users length"
        );
        require(
            bytes(name_).length > 0,
            "WorldEnterprise: Name should not be as empty string"
        );
        require(
            bytes(symbol_).length > 0,
            "WorldEnterprise: Symbol should not be as empty string"
        );
        _name = name_;
        _symbol = symbol_;
        info = info_;

        decimals = 18;
        proposalDelayTime = 60 * 60 * 24 * 7 * 2; // 2 weeks

        for (uint256 i; i < users.length; i++) {
            _mint(users[i], shares[i]);
        }

        transferOwnership(admin);

        emit UpdateInfo(info);
    }

    function voteThreshold() public view returns (uint256) {
        if (_tokenHolders > 5) {
            return 5;
        }
        return _tokenHolders;
    }

    /**
     * Update information of Enterprise
     */
    function updateInfo(
        Enterprise.Info memory info_
    ) external checkInfo(info_) onlyAuthorized {
        info = info_;
        emit UpdateInfo(info);
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
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
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
    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        address owner = msg.sender;
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
    ) public returns (bool) {
        address spender = msg.sender;
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
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        address owner = msg.sender;
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
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "WorldEnterprise: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @param amount propose amount
     * @dev create a propose to join world enterprise
     *
     **/
    function joinWorldEnterprise(
        uint256 amount,
        uint256 price,
        string memory commentUrl
    ) external payable {
        require(
            amount > 0,
            "WorldEnterprise: Amount should be greater than the zero"
        );
        if (price > 0) {
            require(price == msg.value, "WorldEnterprise: Insufficiant fund");
        }

        uint256 _proposalIndex = proposalIndex.current();
        uint256 _startTime = block.timestamp;
        uint256 _endTime = _startTime + proposalDelayTime;

        Proposal memory _proposal = Proposal({
            id: _proposalIndex,
            owner: msg.sender,
            amount: amount,
            commentUrl: commentUrl,
            startTime: _startTime,
            endTime: _endTime,
            yes: 0,
            no: 0,
            status: ProposalStatus.ACTIVE,
            pType: ProposalType.MINT
        });

        proposals[_proposalIndex] = _proposal;
        proposalIndices[msg.sender].push(_proposalIndex);

        proposalIndex.increment();

        emit JoinWorldEnterprise(
            _proposalIndex,
            msg.sender,
            amount,
            price,
            commentUrl,
            _startTime,
            _endTime
        );
    }

    /**
     * @dev create a propose to be admin
     *
     **/
    function handleAdminRequest(bool isAdd) external {
        require(
            balanceOf(msg.sender) > 0,
            "WorldEnterprise: Only token owner can be admin"
        );
        require(
            authorized(msg.sender) != isAdd,
            "WorldEnterprise: invalid admin request"
        );

        uint256 _proposalIndex = proposalIndex.current();
        uint256 _startTime = block.timestamp;
        uint256 _endTime = _startTime + proposalDelayTime;
        ProposalType _type = ProposalType.ADD;
        if (!isAdd) {
            _type = ProposalType.REMOVE;
        }
        Proposal memory _proposal = Proposal({
            id: _proposalIndex,
            owner: msg.sender,
            amount: 0,
            commentUrl: "",
            startTime: _startTime,
            endTime: _endTime,
            yes: 0,
            no: 0,
            status: ProposalStatus.ACTIVE,
            pType: _type
        });

        proposals[_proposalIndex] = _proposal;
        proposalIndices[msg.sender].push(_proposalIndex);

        proposalIndex.increment();

        emit RequestAdminRole(
            _proposalIndex,
            msg.sender,
            isAdd,
            _startTime,
            _endTime
        );
    }

    /**
     * @param _proposalIndex proposal index
     * @param _status vote status
     * @dev vote proposal
     **/
    function vote(uint256 _proposalIndex, bool _status) external {
        Proposal storage _proposal = proposals[_proposalIndex];

        require(
            _proposal.status == ProposalStatus.ACTIVE,
            "WorldEnterprise: Proposal is not active"
        );
        require(
            block.timestamp < _proposal.endTime,
            "WorldEnterprise: Time over to vote for this proposal"
        );
        require(
            balanceOf(msg.sender) > 0,
            "WorldEnterprise: Only token owner can vote"
        );
        require(
            !votes[_proposalIndex][msg.sender],
            "WorldEnterprise: You've already voted for this proposal"
        );

        if (_proposal.pType != ProposalType.MINT) {
            require(
                _proposal.owner != msg.sender,
                "You can not vote for your proposal"
            );
        }

        if (_status) {
            _proposal.yes++;
        } else {
            _proposal.no++;
        }

        votes[_proposalIndex][msg.sender] = true;
        if (_status) {
            emit VoteYes(msg.sender, _proposalIndex);
        } else {
            emit VoteNo(msg.sender, _proposalIndex);
        }
    }

    /**
     * @param _proposalIndex proposal index
     * @dev execute proposal
     **/
    function execute(uint256 _proposalIndex) external {
        Proposal storage _proposal = proposals[_proposalIndex];

        require(
            _proposal.status == ProposalStatus.ACTIVE,
            "WorldEnterprise: Proposal is not active"
        );
        require(
            block.timestamp >= _proposal.endTime,
            "WorldEnterprise: You can execute after the end time"
        );

        uint256 _voteThreshold = voteThreshold();

        if (_proposal.no < _proposal.yes && _voteThreshold <= _proposal.yes) {
            _proposal.status = ProposalStatus.PASSED;

            if (_proposal.pType == ProposalType.MINT) {
                _mint(_proposal.owner, _proposal.amount);
                emit ExecutePassed(
                    _proposalIndex,
                    _proposal.owner,
                    _proposal.amount
                );
            } else if (_proposal.pType == ProposalType.ADD) {
                addAuthorized(_proposal.owner);
                emit ExecuteAdminAddPassed(_proposalIndex, _proposal.owner);
            } else {
                removeAuthorized(_proposal.owner);
                emit ExecuteAdminRemovePassed(_proposalIndex, _proposal.owner);
            }
        } else {
            _proposal.status = ProposalStatus.FAILED;
            emit ExecuteFailed(_proposalIndex);
        }
    }

    /**
     * @param amount token amount
     * @param price price
     * @dev create buy order
     **/
    function createBuyOrder(uint256 amount, uint256 price) external payable {
        require(
            amount > 0,
            "WorldEnterprise: Amount should be greater than the zero"
        );
        require(
            price > 0,
            "WorldEnterprise: Price should be greater than the zero"
        );
        require(
            msg.value >= amount * price,
            "WorldEnterprise: Deposit ETH as much as price"
        );

        uint256 _orderIndex = orderIndex.current();
        Order memory _order = Order({
            id: _orderIndex,
            owner: msg.sender,
            amount: amount,
            price: price,
            orderType: OrderType.BUY,
            status: OrderStatus.ACTIVE
        });

        orders[_orderIndex] = _order;

        orderIndices[msg.sender].push(_orderIndex);

        orderIndex.increment();

        emit CreateBuyOrder(_orderIndex, msg.sender, amount, price);
    }

    /**
     * @param amount token amount
     * @param price price
     * @dev create buy order
     **/
    function createSellOrder(uint256 amount, uint256 price) external {
        require(
            amount > 0,
            "WorldEnterprise: Amount should be greater than the zero"
        );
        require(
            price > 0,
            "WorldEnterprise: Price should be greater than the zero"
        );
        require(
            balanceOf(msg.sender) >= amount * 1 ether,
            "WorldEnterprise: Your token balance is not enough"
        );
        require(
            allowance(msg.sender, address(this)) >= amount * 1 ether,
            "WorldEnterprise: Token allowance is not enough"
        );
        _spendAllowance(msg.sender, address(this), amount * 1 ether);
        _transfer(msg.sender, address(this), amount * 1 ether);

        uint256 _orderIndex = orderIndex.current();
        Order memory _order = Order({
            id: _orderIndex,
            owner: msg.sender,
            amount: amount,
            price: price,
            orderType: OrderType.SELL,
            status: OrderStatus.ACTIVE
        });

        orders[_orderIndex] = _order;

        orderIndices[msg.sender].push(_orderIndex);

        orderIndex.increment();

        emit CreateSellOrder(_orderIndex, msg.sender, amount, price);
    }

    /**
     * @param orderId order id
     * @dev close order
     **/
    function closeOrder(uint256 orderId) external payable {
        Order storage _order = orders[orderId];
        require(
            _order.status == OrderStatus.ACTIVE,
            "WorldEnterprise: Order is not active"
        );

        if (_order.orderType == OrderType.BUY) {
            require(
                balanceOf(msg.sender) >= _order.amount * 1 ether,
                "WorldEnterprise: You have not enough ERC20 token"
            );
            require(
                allowance(msg.sender, address(this)) >= _order.amount * 1 ether,
                "WorldEnterprise: Allownce is not enough to transfer"
            );

            _spendAllowance(msg.sender, address(this), _order.amount * 1 ether);
            _transfer(msg.sender, _order.owner, _order.amount * 1 ether);

            (bool success, ) = (msg.sender).call{
                value: _order.price * _order.amount
            }("");
            require(success, "WorldEnterprise: Withdraw native token error");
        } else if (_order.orderType == OrderType.SELL) {
            require(
                msg.value >= _order.price * _order.amount,
                "WorldEnterprise: ETH is not fair to close"
            );
            require(
                balanceOf(address(this)) >= _order.amount * 1 ether,
                "WorldEnterprise: There is not enough token to sell"
            );

            _transfer(address(this), msg.sender, _order.amount * 1 ether);

            (bool success, ) = (_order.owner).call{
                value: _order.price * _order.amount
            }("");
            require(success, "WorldEnterprise: Withdraw native token error");
        }

        _order.status = OrderStatus.CLOSED;

        emit CloseOrder(orderId);
    }

    /**
     * @param orderId order id
     * @dev cancel order
     **/
    function cancelOrder(uint256 orderId) external {
        Order storage _order = orders[orderId];

        require(
            _order.owner == msg.sender,
            "WorldEnterprise: Only owner can cancel the order"
        );
        require(
            _order.status == OrderStatus.ACTIVE,
            "WorldEnterprise: Order is not active"
        );

        if (_order.orderType == OrderType.BUY) {
            (bool success, ) = (_order.owner).call{
                value: _order.price * _order.amount
            }("");
            require(success, "WorldEnterprise: Withdraw native token error");
        } else if (_order.orderType == OrderType.SELL) {
            require(
                balanceOf(address(this)) >= _order.amount * 1 ether,
                "WorldEnterprise: There is not enought ERC20 token to withdraw"
            );
            require(
                transfer(_order.owner, _order.amount * 1 ether),
                "WorldEnterprise: Withdraw ERC20 token failed"
            );
        }

        _order.status = OrderStatus.CANCELLED;

        emit CancelOrder(orderId);
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
    function _transfer(address from, address to, uint256 amount) internal {
        require(
            from != address(0),
            "WorldEnterprise: transfer from the zero address"
        );
        require(
            to != address(0),
            "WorldEnterprise: transfer to the zero address"
        );

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "WorldEnterprise: transfer amount exceeds balance"
        );

        uint256 _prevToBalance = _balances[to];

        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        if (_balances[from] == 0 && _tokenHolders != 0) {
            _tokenHolders--;
        }

        if (_prevToBalance == 0 && _balances[to] != 0) {
            _tokenHolders++;
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
    function _mint(address account, uint256 amount) internal {
        require(
            account != address(0),
            "WorldEnterprise: mint to the zero address"
        );

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        if (_balances[account] == 0) {
            _tokenHolders++;
        }
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
    function _burn(address account, uint256 amount) internal {
        require(
            account != address(0),
            "WorldEnterprise: burn from the zero address"
        );

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(
            accountBalance >= amount,
            "WorldEnterprise: burn amount exceeds balance"
        );
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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(
            owner != address(0),
            "WorldEnterprise: approve from the zero address"
        );
        require(
            spender != address(0),
            "WorldEnterprise: approve to the zero address"
        );

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
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "WorldEnterprise: insufficient allowance"
            );
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
    ) internal {}

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
    ) internal {}

    /**
     * @param to is wallet address that receives accumulated funds
     * @param value transer amount
     * access admin
     */
    function withdrawAdmin(
        address payable to,
        uint256 value
    ) external onlyAuthorized {
        require(
            to != address(0),
            "WorldEnterprise: Can't withdraw to the zero address."
        );
        require(
            value <= address(this).balance,
            "WorldEnterprise: Withdraw amount exceed the balance of this contract."
        );
        to.transfer(value);
        emit Withdraw(msg.sender, to, value);
    }

    /**
     * @param to is wallet address that receives accumulated funds
     * @param value transer amount
     * access admin
     */
    function withdrawAdminERC20(
        address token,
        address payable to,
        uint256 value
    ) external onlyAuthorized {
        require(
            to != address(0),
            "WorldEnterprise: Can't withdraw to the zero address."
        );
        require(
            value <= IERC20(token).balanceOf(address(this)),
            "WorldEnterprise: Withdraw amount exceed the balance of this contract."
        );
        IERC20(token).transfer(to, value);

        emit WithdrawToken(token, msg.sender, to, value);
    }

    receive() external payable {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

/**
____    __    ____  ______   .______      __       _______      _______ .__   __. .___________._______ .______     .______   .______      __       _______. _______ 
\   \  /  \  /   / /  __  \  |   _  \    |  |     |       \    |   ____||  \ |  | |           |   ____||   _  \    |   _  \  |   _  \    |  |     /       ||   ____|
 \   \/    \/   / |  |  |  | |  |_)  |   |  |     |  .--.  |   |  |__   |   \|  | `---|  |----|  |__   |  |_)  |   |  |_)  | |  |_)  |   |  |    |   (----`|  |__   
  \            /  |  |  |  | |      /    |  |     |  |  |  |   |   __|  |  . `  |     |  |    |   __|  |      /    |   ___/  |      /    |  |     \   \    |   __|  
   \    /\    /   |  `--'  | |  |\  \----|  `----.|  '--'  |   |  |____ |  |\   |     |  |    |  |____ |  |\  \----|  |      |  |\  \----|  | .----)   |   |  |____ 
    \__/  \__/     \______/  | _| `._____|_______||_______/    |_______||__| \__|     |__|    |_______|| _| `._____| _|      | _| `._____|__| |_______/    |_______|
 **/

import "./WorldEnterprise.sol";

contract WorldEnterpriseFactory is Ownable {
    using Counters for Counters.Counter;

    // enterprise index
    Counters.Counter public index;

    /**
     * world enterprise list
     * @dev mapping(world enterprise index => WorldEnterprise)
     **/
    mapping(uint256 => WorldEnterprise) public worldEnterprises;

    /**
     * @dev is world enterprise
     **/
    mapping(address => bool) public isWorldEnterprise;

    event CreateWorldEnterprise(
        uint256 index,
        address admin,
        address[] users,
        uint256[] shares,
        string name,
        string symbol,
        address indexed enterprise,
        Enterprise.Info info
    );

    /**
     *  Emitted when Withdraw
     */
    event Withdraw(address indexed owner, address indexed to, uint256 amount);
    /**
     *  Emitted when WithdrawERC20
     */
    event WithdrawToken(
        address indexed token,
        address indexed owner,
        address indexed to,
        uint256 amount
    );

    modifier checkInfo(Enterprise.Info memory info) {
        require(
            bytes(info.logoImg).length < Enterprise.MAX_LENGTH,
            "WorldEnterpriseFactory: Logo image url should be less than the max length"
        );
        require(
            bytes(info.enterpriseName).length < Enterprise.MAX_LENGTH,
            "WorldEnterpriseFactory: Enterprise name should be less than the max length"
        );
        require(
            bytes(info.description).length < Enterprise.MAX_LENGTH,
            "WorldEnterpriseFactory: Description should be less than the max length"
        );
        require(
            bytes(info.ipfs).length < Enterprise.MAX_LENGTH,
            "WorldEnterpriseFactory: IPFS url should be less than the max length"
        );
        _;
    }

    /**
     * @param users shareholders user array
     * @param shares amount array of shareholders
     * @param tokenName ERC20 token name
     * @param symbol ERC20 token symbol
     *
     * @dev create a new world enterprise
     **/
    function createWorldEnterprise(
        address admin,
        address[] calldata users,
        uint256[] calldata shares,
        string calldata tokenName,
        string calldata symbol,
        Enterprise.Info memory info
    ) external checkInfo(info) {
        require(
            users.length > 0,
            "WorldEnterpriseFactory: Users length should be greater than the zero"
        );
        require(
            users.length == shares.length,
            "WorldEnterpriseFactory: Shares length should be equal with the users length"
        );
        require(
            bytes(tokenName).length > 0,
            "WorldEnterpriseFactory: Token name should not be as empty string"
        );
        require(
            bytes(symbol).length > 0,
            "WorldEnterpriseFactory: Symbol should not be as empty string"
        );

        WorldEnterprise _worldEnterprise = new WorldEnterprise(
            admin,
            users,
            shares,
            tokenName,
            symbol,
            info
        );
        uint256 _index = index.current();
        worldEnterprises[_index] = _worldEnterprise;

        isWorldEnterprise[address(_worldEnterprise)] = true;

        index.increment();

        emit CreateWorldEnterprise(
            _index,
            admin,
            users,
            shares,
            tokenName,
            symbol,
            address(_worldEnterprise),
            info
        );
    }

    /**
     * @param to is wallet address that receives accumulated funds
     * @param value transer amount
     * access admin
     */
    function withdrawAdmin(
        address payable to,
        uint256 value
    ) external onlyOwner {
        require(
            to != address(0),
            "WorldEnterpriseFactory: Can't withdraw to the zero address."
        );
        require(
            value <= address(this).balance,
            "WorldEnterpriseFactory: Withdraw amount exceed the balance of this contract."
        );
        to.transfer(value);
        emit Withdraw(owner(), to, value);
    }

    /**
     * @param to is wallet address that receives accumulated funds
     * @param value transer amount
     * access admin
     */
    function withdrawAdminERC20(
        address token,
        address payable to,
        uint256 value
    ) external onlyOwner {
        require(
            to != address(0),
            "WorldEnterpriseFactory: Can't withdraw to the zero address."
        );
        require(
            value <= IERC20(token).balanceOf(address(this)),
            "WorldEnterpriseFactory: Withdraw amount exceed the balance of this contract."
        );
        IERC20(token).transfer(to, value);

        emit WithdrawToken(token, owner(), to, value);
    }

    receive() external payable {}
}