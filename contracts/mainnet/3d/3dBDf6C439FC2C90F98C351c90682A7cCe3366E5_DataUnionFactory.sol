/**
 *Submitted for verification at polygonscan.com on 2022-04-05
*/

// Sources flattened with hardhat v2.9.2 https://hardhat.org
// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}


// File @openzeppelin/contracts/proxy/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}


// File contracts/xdai-mainnet-bridge/IAMB.sol


pragma solidity 0.8.6;

// Tokenbridge Arbitrary Message Bridge
interface IAMB {

    //only on mainnet AMB:
    function executeSignatures(bytes calldata _data, bytes calldata _signatures) external;

    function messageSender() external view returns (address);

    function maxGasPerTx() external view returns (uint256);

    function transactionHash() external view returns (bytes32);

    function messageId() external view returns (bytes32);

    function messageSourceChainId() external view returns (bytes32);

    function messageCallStatus(bytes32 _messageId) external view returns (bool);

    function requiredSignatures() external view returns (uint256);
    function numMessagesSigned(bytes32 _message) external view returns (uint256);
    function signature(bytes32 _hash, uint256 _index) external view returns (bytes memory);
    function message(bytes32 _hash) external view returns (bytes memory);
    function failedMessageDataHash(bytes32 _messageId)
        external
        view
        returns (bytes32);

    function failedMessageReceiver(bytes32 _messageId)
        external
        view
        returns (address);

    function failedMessageSender(bytes32 _messageId)
        external
        view
        returns (address);

    function requireToPassMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);
}


// File contracts/IERC677.sol


pragma solidity 0.8.6;

interface IERC677 is IERC20 {
    function transferAndCall(
        address to,
        uint value,
        bytes calldata data
    ) external returns (bool success);

    event Transfer(
        address indexed from,
        address indexed to,
        uint value,
        bytes data
    );
}


// File contracts/Ownable.sol


pragma solidity 0.8.6;

// TODO: maybe replace this with OpenZeppelin ownable if we give up the factory pattern: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 *
 * Open Zeppelin's ownable doesn't quite work with factory pattern because _owner has private access.
 * When you create a DU, open-zeppelin _owner would be 0x0 (no state from template). Then no address could change _owner to the DU owner.
 * With this custom Ownable, the first person to call initialiaze() can set owner.
 */
contract Ownable {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor(address owner_) {
        owner = owner_;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "error_onlyOwner");
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public {
        require(msg.sender == pendingOwner, "error_onlyPendingOwner");
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}


// File contracts/xdai-mainnet-bridge/IERC20Receiver.sol


pragma solidity 0.8.6;

/*
tokenbridge callback function for receiving relayTokensAndCall()
*/
interface IERC20Receiver {
    function onTokenBridged(
        address token,
        uint256 value,
        bytes calldata data
    ) external;
}


// File contracts/IERC677Receiver.sol


pragma solidity 0.8.6;

interface IERC677Receiver {
    function onTokenTransfer(
        address _sender,
        uint256 _value,
        bytes calldata _data
    ) external;
}


// File contracts/IWithdrawModule.sol


pragma solidity 0.8.6;

interface IWithdrawModule {
    /**
     * When a withdraw happens in the DU, tokens are transferred to the withdrawModule, then onWithdraw function is called.
     * The withdrawModule is then free to manage those tokens as it pleases.
     */
    function onWithdraw(address member, address to, IERC677 token, uint amountWei) external;

    /**
     * WithdrawModule can also set limits to withdraws between 0 and (earnings - previously withdrawn earnings).
     */
    function getWithdrawLimit(address member, uint maxWithdrawable) external view returns (uint256);
}


// File contracts/IJoinListener.sol


pragma solidity 0.8.6;

interface IJoinListener {
    function onJoin(address newMember) external;
}


// File contracts/LeaveConditionCode.sol


pragma solidity 0.8.6;

/**
 * Describes how the data union member left
 * For the base DataUnion contract this isn't important, but modules/extensions can find it very helpful
 * See e.g. LimitWithdrawModule
 */
enum LeaveConditionCode {
    SELF,   // self remove using partMember()
    AGENT,  // removed by joinPartAgent using partMember()
    BANNED  // removed by BanModule
}


// File contracts/IPartListener.sol


pragma solidity 0.8.6;

interface IPartListener {
    function onPart(address leavingMember, LeaveConditionCode leaveConditionCode) external;
}


// File contracts/unichain/DataUnionTemplate.sol


pragma solidity 0.8.6;


// TODO: switch to "@openzeppelin/contracts/access/Ownable.sol";







contract DataUnionTemplate is Ownable, IERC677Receiver {
    // Used to describe both members and join part agents
    enum ActiveStatus {NONE, ACTIVE, INACTIVE}

    // Members
    event MemberJoined(address indexed member);
    event MemberParted(address indexed member, LeaveConditionCode indexed leaveConditionCode);
    event JoinPartAgentAdded(address indexed agent);
    event JoinPartAgentRemoved(address indexed agent);
    event NewMemberEthSent(uint amountWei);

    // Revenue handling: earnings = revenue - admin fee - du fee
    event RevenueReceived(uint256 amount);
    event FeesCharged(uint256 adminFee, uint256 dataUnionFee);
    event NewEarnings(uint256 earningsPerMember, uint256 activeMemberCount);

    // Withdrawals
    event EarningsWithdrawn(address indexed member, uint256 amount);

    // Modules and hooks
    event WithdrawModuleChanged(IWithdrawModule indexed withdrawModule);
    event JoinListenerAdded(IJoinListener indexed listener);
    event JoinListenerRemoved(IJoinListener indexed listener);
    event PartListenerAdded(IPartListener indexed listener);
    event PartListenerRemoved(IPartListener indexed listener);

    // In-contract transfers
    event TransferWithinContract(address indexed from, address indexed to, uint amount);
    event TransferToAddressInContract(address indexed from, address indexed to, uint amount);

    // Variable properties change events
    event UpdateNewMemberEth(uint value);
    event FeesSet(uint256 adminFee, uint256 dataUnionFee);
    event DataUnionBeneficiaryChanged(address indexed current, address indexed old);

    struct MemberInfo {
        ActiveStatus status;
        uint256 earningsBeforeLastJoin;
        uint256 lmeAtJoin;
        uint256 withdrawnEarnings;
    }

    // Constant properties (only set in initialize)
    IERC677 public token;

    // Modules
    IWithdrawModule public withdrawModule;
    // TODO: once we can cast  address[] storage listeners = joinListeners;  then use these interface types
    // IJoinListener[] public joinListeners;
    // IPartListener[] public partListeners;
    address[] public joinListeners;
    address[] public partListeners;
    bool public modulesLocked;

    // Variable properties
    uint256 public newMemberEth;
    uint256 public adminFeeFraction;
    uint256 public dataUnionFeeFraction;
    address public dataUnionBeneficiary;

    // Useful stats
    uint256 public totalRevenue;
    uint256 public totalEarnings;
    uint256 public totalAdminFees;
    uint256 public totalDataUnionFees;
    uint256 public totalWithdrawn;
    uint256 public activeMemberCount;
    uint256 public inactiveMemberCount;
    uint256 public lifetimeMemberEarnings;
    uint256 public joinPartAgentCount;

    mapping(address => MemberInfo) public memberData;
    mapping(address => ActiveStatus) public joinPartAgents;

    // owner will be set by initialize()
    constructor() Ownable(address(0)) {}

    receive() external payable {}

    function initialize(
        address initialOwner,
        address tokenAddress,
        address[] memory initialJoinPartAgents,
        uint256 defaultNewMemberEth,
        uint256 initialAdminFeeFraction,
        uint256 initialDataUnionFeeFraction,
        address initialDataUnionBeneficiary
    ) public {
        require(!isInitialized(), "error_alreadyInitialized");
        owner = msg.sender; // set real owner at the end. During initialize, addJoinPartAgents can be called by owner only
        token = IERC677(tokenAddress);
        addJoinPartAgents(initialJoinPartAgents);
        setFees(initialAdminFeeFraction, initialDataUnionFeeFraction);
        setDataUnionBeneficiary(initialDataUnionBeneficiary);
        setNewMemberEth(defaultNewMemberEth);
        owner = initialOwner;
    }

    function isInitialized() public view returns (bool){
        return address(token) != address(0);
    }

    /**
     * Atomic getter to get all Data Union state variables in one call
     * This alleviates the fact that JSON RPC batch requests aren't available in ethers.js
     */
    function getStats() public view returns (uint256[9] memory) {
        uint256 cleanedInactiveMemberCount = inactiveMemberCount;
        if (memberData[owner].status == ActiveStatus.INACTIVE) { cleanedInactiveMemberCount -= 1; }
        if (memberData[dataUnionBeneficiary].status == ActiveStatus.INACTIVE) { cleanedInactiveMemberCount -= 1; }
        return [
            totalRevenue,
            totalEarnings,
            totalAdminFees,
            totalDataUnionFees,
            totalWithdrawn,
            activeMemberCount,
            cleanedInactiveMemberCount,
            lifetimeMemberEarnings,
            joinPartAgentCount
        ];
    }

    /**
     * Admin and DU fees as a fraction of revenue,
     *   using fixed-point decimal in the same way as ether: 50% === 0.5 ether === "500000000000000000"
     * @param newAdminFee fee that goes to the DU owner
     * @param newDataUnionFee fee that goes to the DU beneficiary
     */
    function setFees(uint256 newAdminFee, uint256 newDataUnionFee) public onlyOwner {
        require((newAdminFee + newDataUnionFee) <= 1 ether, "error_fees");
        adminFeeFraction = newAdminFee;
        dataUnionFeeFraction = newDataUnionFee;
        emit FeesSet(adminFeeFraction, dataUnionFeeFraction);
    }

    function setDataUnionBeneficiary(address newDataUnionBeneficiary) public onlyOwner {
        emit DataUnionBeneficiaryChanged(newDataUnionBeneficiary, dataUnionBeneficiary);
        dataUnionBeneficiary = newDataUnionBeneficiary;
    }

    function setNewMemberEth(uint val) public onlyOwner {
        newMemberEth = val;
        emit UpdateNewMemberEth(val);
    }

    //------------------------------------------------------------
    // REVENUE HANDLING FUNCTIONS
    //------------------------------------------------------------

    /**
     * Process unaccounted tokens that have been sent previously
     * Called by AMB (see DataUnionMainnet:sendTokensToBridge)
     */
    function refreshRevenue() public returns (uint256) {
        uint256 balance = token.balanceOf(address(this));
        uint256 newTokens = balance - totalWithdrawable(); // since 0.8.0 version of solidity, a - b errors if b > a
        if (newTokens == 0 || activeMemberCount == 0) { return 0; }
        totalRevenue += newTokens;
        emit RevenueReceived(newTokens);

        // fractions are expressed as multiples of 10^18 just like tokens, so must divide away the extra 10^18 factor
        // overflow in multiplication is not an issue: 256bits ~= 10^77
        uint256 adminFee = (newTokens * adminFeeFraction) / (1 ether);
        uint256 duFee = (newTokens * dataUnionFeeFraction) / (1 ether);
        uint256 newEarnings = newTokens - adminFee - duFee;

        _increaseBalance(owner, adminFee);
        _increaseBalance(dataUnionBeneficiary, duFee);
        totalAdminFees += adminFee;
        totalDataUnionFees += duFee;
        emit FeesCharged(adminFee, duFee);

        uint256 earningsPerMember = newEarnings / activeMemberCount;
        lifetimeMemberEarnings = lifetimeMemberEarnings + earningsPerMember;
        totalEarnings = totalEarnings + newEarnings;
        emit NewEarnings(earningsPerMember, activeMemberCount);

        assert (token.balanceOf(address(this)) == totalWithdrawable()); // calling this function immediately again should just return 0 and do nothing
        return newEarnings;
    }

    /**
     * ERC677 callback function, see https://github.com/ethereum/EIPs/issues/677
     * Receives the tokens arriving through bridge
     * Only the token contract is authorized to call this function
     */
    function onTokenTransfer(address, uint256, bytes calldata) override external {
        // guarding refreshRevenue is pointless, but this prevents DU from receiving unexpected ERC677 tokens
        require(msg.sender == address(token), "error_onlyTokenContract");
        refreshRevenue();
    }

    //------------------------------------------------------------
    // EARNINGS VIEW FUNCTIONS
    //------------------------------------------------------------

    function getEarnings(address member) public view returns (uint256) {
        MemberInfo storage info = memberData[member];
        require(info.status != ActiveStatus.NONE, "error_notMember");
        return
            info.earningsBeforeLastJoin +
            (
                info.status == ActiveStatus.ACTIVE
                    ? lifetimeMemberEarnings - info.lmeAtJoin
                    : 0
            );
    }

    function getWithdrawn(address member) public view returns (uint256) {
        MemberInfo storage info = memberData[member];
        require(info.status != ActiveStatus.NONE, "error_notMember");
        return info.withdrawnEarnings;
    }

    function getWithdrawableEarnings(address member) public view returns (uint256) {
        uint maxWithdraw = getEarnings(member) - getWithdrawn(member);
        if (address(withdrawModule) != address(0)) {
            uint moduleLimit = withdrawModule.getWithdrawLimit(member, maxWithdraw);
            if (moduleLimit < maxWithdraw) { maxWithdraw = moduleLimit; }
        }
        return maxWithdraw;
    }

    // this includes the fees paid to admins and the DU beneficiary
    function totalWithdrawable() public view returns (uint256) {
        return totalRevenue - totalWithdrawn;
    }

    //------------------------------------------------------------
    // MEMBER MANAGEMENT / VIEW FUNCTIONS
    //------------------------------------------------------------

    function isMember(address member) public view returns (bool) {
        return memberData[member].status == ActiveStatus.ACTIVE;
    }

    function isJoinPartAgent(address agent) public view returns (bool) {
        return joinPartAgents[agent] == ActiveStatus.ACTIVE;
    }

    modifier onlyJoinPartAgent() {
        require(isJoinPartAgent(msg.sender), "error_onlyJoinPartAgent");
        _;
    }

    function addJoinPartAgents(address[] memory agents) public onlyOwner {
        for (uint256 i = 0; i < agents.length; i++) {
            addJoinPartAgent(agents[i]);
        }
    }

    function addJoinPartAgent(address agent) public onlyOwner {
        require(joinPartAgents[agent] != ActiveStatus.ACTIVE, "error_alreadyActiveAgent");
        joinPartAgents[agent] = ActiveStatus.ACTIVE;
        emit JoinPartAgentAdded(agent);
        joinPartAgentCount += 1;
    }

    function removeJoinPartAgent(address agent) public onlyOwner {
        require(joinPartAgents[agent] == ActiveStatus.ACTIVE, "error_notActiveAgent");
        joinPartAgents[agent] = ActiveStatus.INACTIVE;
        emit JoinPartAgentRemoved(agent);
        joinPartAgentCount -= 1;
    }

    function addMember(address payable newMember) public onlyJoinPartAgent {
        MemberInfo storage info = memberData[newMember];
        require(!isMember(newMember), "error_alreadyMember");
        if (info.status == ActiveStatus.INACTIVE) {
            inactiveMemberCount -= 1;
        }
        bool sendEth = info.status == ActiveStatus.NONE && newMemberEth > 0 && address(this).balance >= newMemberEth;
        info.status = ActiveStatus.ACTIVE;
        info.lmeAtJoin = lifetimeMemberEarnings;
        activeMemberCount += 1;
        emit MemberJoined(newMember);

        // listeners get a chance to reject the new member by reverting
        for (uint i = 0; i < joinListeners.length; i++) {
            address listener = joinListeners[i];
            IJoinListener(listener).onJoin(newMember); // may revert
        }

        // give new members ETH. continue even if transfer fails
        if (sendEth) {
            if (newMember.send(newMemberEth)) {
                emit NewMemberEthSent(newMemberEth);
            }
        }
        refreshRevenue();
    }

    function removeMember(address member, LeaveConditionCode leaveConditionCode) public {
        require(msg.sender == member || joinPartAgents[msg.sender] == ActiveStatus.ACTIVE, "error_notPermitted");
        require(isMember(member), "error_notActiveMember");

        memberData[member].earningsBeforeLastJoin = getEarnings(member);
        memberData[member].status = ActiveStatus.INACTIVE;
        activeMemberCount -= 1;
        inactiveMemberCount += 1;
        emit MemberParted(member, leaveConditionCode);

        // listeners do NOT get a chance to prevent parting by reverting
        for (uint i = 0; i < partListeners.length; i++) {
            address listener = partListeners[i];
            try IPartListener(listener).onPart(member, leaveConditionCode) { } catch { }
        }

        refreshRevenue();
    }

    // access checked in removeMember
    function partMember(address member) public {
        removeMember(member, msg.sender == member ? LeaveConditionCode.SELF : LeaveConditionCode.AGENT);
    }

    // access checked in addMember
    function addMembers(address payable[] calldata members) external {
        for (uint256 i = 0; i < members.length; i++) {
            addMember(members[i]);
        }
    }

    // access checked in removeMember
    function partMembers(address[] calldata members) external {
        for (uint256 i = 0; i < members.length; i++) {
            partMember(members[i]);
        }
    }

    //------------------------------------------------------------
    // IN-CONTRACT TRANSFER FUNCTIONS
    //------------------------------------------------------------

    /**
     * Transfer tokens from outside contract, add to a recipient's in-contract balance. Skip admin and DU fees etc.
     */
    function transferToMemberInContract(address recipient, uint amount) public {
        // this is done first, so that in case token implementation calls the onTokenTransfer in its transferFrom (which by ERC677 it should NOT),
        //   transferred tokens will still not count as earnings (distributed to all) but a simple earnings increase to this particular member
        _increaseBalance(recipient, amount);
        totalRevenue += amount;
        emit TransferToAddressInContract(msg.sender, recipient, amount);

        uint balanceBefore = token.balanceOf(address(this));
        require(token.transferFrom(msg.sender, address(this), amount), "error_transfer");
        uint balanceAfter = token.balanceOf(address(this));
        require((balanceAfter - balanceBefore) >= amount, "error_transfer");

        refreshRevenue();
    }

    /**
     * Transfer tokens from sender's in-contract balance to recipient's in-contract balance
     * This is done by "withdrawing" sender's earnings and crediting them to recipient's unwithdrawn earnings,
     *   so withdrawnEarnings never decreases for anyone (within this function)
     * @param recipient whose withdrawable earnings will increase
     * @param amount how much withdrawable earnings is transferred
     */
    function transferWithinContract(address recipient, uint amount) public {
        require(getWithdrawableEarnings(msg.sender) >= amount, "error_insufficientBalance");    // reverts with "error_notMember" msg.sender not member
        MemberInfo storage info = memberData[msg.sender];
        info.withdrawnEarnings = info.withdrawnEarnings + amount;
        _increaseBalance(recipient, amount);
        emit TransferWithinContract(msg.sender, recipient, amount);
        refreshRevenue();
    }

    /**
     * Hack to add to single member's balance without affecting lmeAtJoin
     */
    function _increaseBalance(address member, uint amount) internal {
        MemberInfo storage info = memberData[member];
        info.earningsBeforeLastJoin = info.earningsBeforeLastJoin + amount;

        // allow seeing and withdrawing earnings
        if (info.status == ActiveStatus.NONE) {
            info.status = ActiveStatus.INACTIVE;
            inactiveMemberCount += 1;
        }
    }

    //------------------------------------------------------------
    // WITHDRAW FUNCTIONS
    //------------------------------------------------------------

    /**
     * @param sendToMainnet Deprecated
     */
    function withdrawMembers(address[] calldata members, bool sendToMainnet)
        external
        returns (uint256)
    {
        uint256 withdrawn = 0;
        for (uint256 i = 0; i < members.length; i++) {
            withdrawn = withdrawn + (withdrawAll(members[i], sendToMainnet));
        }
        return withdrawn;
    }

    /**
     * @param sendToMainnet Deprecated
     */
    function withdrawAll(address member, bool sendToMainnet)
        public
        returns (uint256)
    {
        refreshRevenue();
        return withdraw(member, getWithdrawableEarnings(member), sendToMainnet);
    }

    /**
     * @param sendToMainnet Deprecated
     */
    function withdraw(address member, uint amount, bool sendToMainnet)
        public
        returns (uint256)
    {
        require(msg.sender == member || msg.sender == owner, "error_notPermitted");
        return _withdraw(member, member, amount, sendToMainnet);
    }

    /**
     * @param sendToMainnet Deprecated
     */
    function withdrawAllTo(address to, bool sendToMainnet)
        external
        returns (uint256)
    {
        refreshRevenue();
        return withdrawTo(to, getWithdrawableEarnings(msg.sender), sendToMainnet);
    }

    /**
     * @param sendToMainnet Deprecated
     */
    function withdrawTo(address to, uint amount, bool sendToMainnet)
        public
        returns (uint256)
    {
        return _withdraw(msg.sender, to, amount, sendToMainnet);
    }

    /**
     * Check signature from a member authorizing withdrawing its earnings to another account.
     * Throws if the signature is badly formatted or doesn't match the given signer and amount.
     * Signature has parts the act as replay protection:
     * 1) `address(this)`: signature can't be used for other contracts;
     * 2) `withdrawn[signer]`: signature only works once (for unspecified amount), and can be "cancelled" by sending a withdraw tx.
     * Generated in Javascript with: `web3.eth.accounts.sign(recipientAddress + amount.toString(16, 64) + contractAddress.slice(2) + withdrawnTokens.toString(16, 64), signerPrivateKey)`,
     * or for unlimited amount: `web3.eth.accounts.sign(recipientAddress + "0".repeat(64) + contractAddress.slice(2) + withdrawnTokens.toString(16, 64), signerPrivateKey)`.
     * @param signer whose earnings are being withdrawn
     * @param recipient of the tokens
     * @param amount how much is authorized for withdraw, or zero for unlimited (withdrawAll)
     * @param signature byte array from `web3.eth.accounts.sign`
     * @return isValid true iff signer of the authorization (member whose earnings are going to be withdrawn) matches the signature
     */
    function signatureIsValid(
        address signer,
        address recipient,
        uint amount,
        bytes memory signature
    )
        public view
        returns (bool isValid)
    {
        require(signature.length == 65, "error_badSignatureLength");

        bytes32 r; bytes32 s; uint8 v;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "error_badSignatureVersion");

        // When changing the message, remember to double-check that message length is correct!
        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n104", recipient, amount, address(this), getWithdrawn(signer)));
        address calculatedSigner = ecrecover(messageHash, v, r, s);

        return calculatedSigner == signer;
    }

    /**
     * Do an "unlimited donate withdraw" on behalf of someone else, to an address they've specified.
     * Sponsored withdraw is paid by admin, but target account could be whatever the member specifies.
     * The signature gives a "blank cheque" for admin to withdraw all tokens to `recipient` in the future,
     *   and it's valid until next withdraw (and so can be nullified by withdrawing any amount).
     * A new signature needs to be obtained for each subsequent future withdraw.
     * @param fromSigner whose earnings are being withdrawn
     * @param to the address the tokens will be sent to (instead of `msg.sender`)
     * @param sendToMainnet Deprecated
     * @param signature from the member, see `signatureIsValid` how signature generated for unlimited amount
     */
    function withdrawAllToSigned(
        address fromSigner,
        address to,
        bool sendToMainnet,
        bytes calldata signature
    )
        external
        returns (uint withdrawn)
    {
        require(signatureIsValid(fromSigner, to, 0, signature), "error_badSignature");
        refreshRevenue();
        return _withdraw(fromSigner, to, getWithdrawableEarnings(fromSigner), sendToMainnet);
    }

    /**
     * Do a "donate withdraw" on behalf of someone else, to an address they've specified.
     * Sponsored withdraw is paid by admin, but target account could be whatever the member specifies.
     * The signature is valid only for given amount of tokens that may be different from maximum withdrawable tokens.
     * @param fromSigner whose earnings are being withdrawn
     * @param to the address the tokens will be sent to (instead of `msg.sender`)
     * @param amount of tokens to withdraw
     * @param sendToMainnet Deprecated
     * @param signature from the member, see `signatureIsValid` how signature generated for unlimited amount
     */
    function withdrawToSigned(
        address fromSigner,
        address to,
        uint amount,
        bool sendToMainnet,
        bytes calldata signature
    )
        external
        returns (uint withdrawn)
    {
        require(signatureIsValid(fromSigner, to, amount, signature), "error_badSignature");
        return _withdraw(fromSigner, to, amount, sendToMainnet);
    }

    /**
     * Internal function common to all withdraw methods.
     * Does NOT check proper access, so all callers must do that first.
     */
    function _withdraw(address from, address to, uint amount, bool sendToMainnet)
        internal
        returns (uint256)
    {
        if (amount == 0) { return 0; }
        refreshRevenue();
        require(amount <= getWithdrawableEarnings(from), "error_insufficientBalance");
        MemberInfo storage info = memberData[from];
        info.withdrawnEarnings += amount;
        totalWithdrawn += amount;

        if (address(withdrawModule) != address(0)) {
            require(token.transfer(address(withdrawModule), amount), "error_transfer");
            withdrawModule.onWithdraw(from, to, token, amount);
        } else {
            _defaultWithdraw(from, to, amount, sendToMainnet);
        }

        emit EarningsWithdrawn(from, amount);
        return amount;
    }

    /**
     * Default DU 2.1 withdraw functionality, can be overridden with a withdrawModule.
     * @param sendToMainnet Deprecated
     */
    function _defaultWithdraw(address from, address to, uint amount, bool sendToMainnet)
        internal
    {
        require(!sendToMainnet, "error_sendToMainnetDeprecated");
        // transferAndCall also enables transfers over another token bridge
        //   in this case to=another bridge's tokenMediator, and from=recipient on the other chain
        // this follows the tokenMediator API: data will contain the recipient address, which is the same as sender but on the other chain
        // in case transferAndCall recipient is not a tokenMediator, the data can be ignored (it contains the DU member's address)
        require(token.transferAndCall(to, amount, abi.encodePacked(from)), "error_transfer");
    }

    //------------------------------------------------------------
    // MODULE MANAGEMENT
    //------------------------------------------------------------

    /**
     * @param newWithdrawModule set to zero to return to the default withdraw functionality
     */
    function setWithdrawModule(IWithdrawModule newWithdrawModule) external onlyOwner {
        require(!modulesLocked, "error_modulesLocked");
        // TODO: check EIP-165?
        withdrawModule = newWithdrawModule;
        emit WithdrawModuleChanged(newWithdrawModule);
    }

    function addJoinListener(IJoinListener newListener) external onlyOwner {
        // TODO: check EIP-165?
        joinListeners.push(address(newListener));
        emit JoinListenerAdded(newListener);
    }

    function addPartListener(IPartListener newListener) external onlyOwner {
        // TODO: check EIP-165?
        partListeners.push(address(newListener));
        emit PartListenerAdded(newListener);
    }

    function removeJoinListener(IJoinListener listener) external onlyOwner {
        require(removeFromAddressArray(joinListeners, address(listener)), "error_joinListenerNotFound");
        emit JoinListenerRemoved(listener);
    }

    function removePartListener(IPartListener listener) external onlyOwner {
        require(removeFromAddressArray(partListeners, address(listener)), "error_partListenerNotFound");
        emit PartListenerRemoved(listener);
    }

    /**
     * Remove the listener from array by copying the last element into its place so that the arrays stay compact
     */
    function removeFromAddressArray(address[] storage array, address element) internal returns (bool success) {
        uint i = 0;
        while (i < array.length && array[i] != element) { i += 1; }
        if (i == array.length) return false;

        if (i < array.length - 1) {
            array[i] = array[array.length - 1];
        }
        array.pop();
        return true;
    }

    function lockModules() public onlyOwner {
        modulesLocked = true;
    }
}


// File contracts/unichain/DataUnionFactory.sol


pragma solidity 0.8.6;




// TODO: switch to "@openzeppelin/contracts/access/Ownable.sol";

contract DataUnionFactory is Ownable {
    event SidechainDUCreated(address indexed mainnet, address indexed sidenet, address indexed owner, address template);
    event DUCreated(address indexed du, address indexed owner, address template);
    event UpdateNewDUInitialEth(uint amount);
    event UpdateNewDUOwnerInitialEth(uint amount);
    event UpdateDefaultNewMemberInitialEth(uint amount);
    event DUInitialEthSent(uint amountWei);
    event OwnerInitialEthSent(uint amountWei);

    address public dataUnionTemplate;
    address public defaultToken;

    // when sidechain DU is created, the factory sends a bit of sETH to the DU and the owner
    uint public newDUInitialEth;
    uint public newDUOwnerInitialEth;
    uint public defaultNewMemberEth;

    constructor(
        address _dataUnionTemplate,
        address _defaultToken
    ) Ownable(msg.sender) {
        setTemplate(_dataUnionTemplate);
        defaultToken = _defaultToken;
    }

    function setTemplate(address _dataUnionTemplate) public onlyOwner {
        dataUnionTemplate = _dataUnionTemplate;
    }

    // contract is payable so it can receive and hold the new member eth stipends
    receive() external payable {}

    function setNewDUInitialEth(uint val) public onlyOwner {
        newDUInitialEth = val;
        emit UpdateNewDUInitialEth(val);
    }

    function setNewDUOwnerInitialEth(uint val) public onlyOwner {
        newDUOwnerInitialEth = val;
        emit UpdateNewDUOwnerInitialEth(val);
    }

    function setNewMemberInitialEth(uint val) public onlyOwner {
        defaultNewMemberEth = val;
        emit UpdateDefaultNewMemberInitialEth(val);
    }

    function deployNewDataUnion(
        address payable owner,
        uint256 adminFeeFraction,
        uint256 duFeeFraction,
        address duBeneficiary,
        address[] memory agents
    )
        public
        returns (address)
    {
        return deployNewDataUnionUsingToken(
            defaultToken,
            owner,
            agents,
            adminFeeFraction,
            duFeeFraction,
            duBeneficiary
        );
    }
    /**
     * @dev This function is called over the bridge by the DataUnionMainnet.initialize function
     * @dev Hence must be called by the AMB. Use MockAMB for testing.
     * @dev CREATE2 salt = mainnet_address.
     */
    function deployNewDataUnionUsingToken(
        address token,
        address payable owner,
        address[] memory agents,
        uint256 initialAdminFeeFraction,
        uint256 initialDataUnionFeeFraction,
        address initialDataUnionBeneficiary
    ) public returns (address) {
        address payable du = payable(Clones.clone(dataUnionTemplate));
        DataUnionTemplate(du).initialize(
            owner,
            token,
            agents,
            defaultNewMemberEth,
            initialAdminFeeFraction,
            initialDataUnionFeeFraction,
            initialDataUnionBeneficiary
        );
        
        emit SidechainDUCreated(du, du, owner, dataUnionTemplate);
        emit DUCreated(du, owner, dataUnionTemplate);

        // continue whether or not send succeeds
        if (newDUInitialEth != 0 && address(this).balance >= newDUInitialEth) {
            if (du.send(newDUInitialEth)) {
                emit DUInitialEthSent(newDUInitialEth);
            }
        }
        if (newDUOwnerInitialEth != 0 && address(this).balance >= newDUOwnerInitialEth) {
            // solhint-disable-next-line multiple-sends
            if (owner.send(newDUOwnerInitialEth)) {
                emit OwnerInitialEthSent(newDUOwnerInitialEth);
            }
        }
        return du;
    }
}