//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {ContextUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IDAOInterface.sol";
import "./interfaces/IVotingInterface.sol";
import "./interfaces/ITokenInterface.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./Voting.sol";

contract CrossGovVoting is ContextUpgradeable, ICrossGovVotingInterface {
    using Address for address;
    using ECDSAUpgradeable for bytes32;

    struct Option {
        string name;
        uint amount;
    }

    struct VoteResult {
        uint id;
        uint optionIndex;
        uint amount;
    }

    uint public curId;
    uint public chainId;
    address public daoAddr;
    address[] public trustedAddr;
    mapping(uint => Proposal) internal proposalMap; // id => Proposal
    mapping(address => mapping(uint => VoteResult)) public voteResults;//address => proposalId => VoteResult
    mapping(uint => Option[]) public optionsMap;//proposalId => Option
    mapping(address => mapping(uint => bool)) public existedNonce;

    enum SigType{
        CreateProposal,
        Vote
    }
    struct VoteInfo {
        address user;
        uint weight;
        uint chainId;
        address voting;
        uint nonce;
        SigType sigType;
    }

    event CreateProposal(uint indexed id, uint ty, address from, address to, uint amount, uint startTime, uint endTime);
    event CancelProposal(uint indexed id, address from, address to, uint amount);
    event Vote(uint indexed id, address indexed user, uint amount, uint optionIndex);
    event ExecuteProposal(uint indexed id, bool isSuccess);

    function initialize(address dao, uint _chainId, address[] memory _trustedAddr) initializer override public {
        daoAddr = dao;
        chainId = _chainId;
        copyAddr(_trustedAddr, trustedAddr);
        __Context_init();
    }

    function getOptionsById(uint id) public view returns (Option[] memory) {
        return optionsMap[id];
    }

    //create Contract proposal
    function createContractProposal(string calldata title, string calldata content, VoteInfo calldata voteInfo,
        bytes calldata signature, bytes memory data) public {
        Option[] memory options = new Option[](2);
        options[0] = Option("approve", 0);
        options[1] = Option("disapprove", 0);
        createProposal(ProposalType.Contract, title, content, 0, 0, options, data, voteInfo, signature);
    }

    function createCommunityProposal(string calldata title, string calldata content,
        uint startTime, uint endTime, string[] calldata _options, VoteInfo calldata voteInfo,
        bytes calldata signature) public {
        Option[] memory options = new Option[](_options.length);
        for (uint i = 0; i < _options.length; i++) {
            options[i] = Option(_options[i], 0);
        }
        createProposal(ProposalType.Community, title, content, startTime, endTime, options, new bytes(0), voteInfo, signature);
    }

    function createProposal(ProposalType ty, string memory title, string memory content, uint startTime,
        uint endTime, Option[] memory options, bytes memory data,
        VoteInfo calldata voteInfo, bytes calldata signature) internal {
        if (ty == ProposalType.Contract) {
            require(data.length >= 4, "invalid data");
            require(IERC165Upgradeable(daoAddr).supportsInterface(convertBytesToBytes4(data)), "not support method");
        }
        require(voteInfo.sigType == SigType.CreateProposal, "invalid SigType");
        require(verifyVote(voteInfo, signature), "invalid vote parameter");
        existedNonce[msg.sender][voteInfo.nonce] = true;
        IDAOCrossGovInterface.DAORule memory rule = IDAOCrossGovInterface(daoAddr).getDaoRule();
        require(voteInfo.weight >= rule.minimumCreateProposal, "balance < minimumCreateProposal");
        uint id = getNextId();
        increaseId();
        // user defined
        if (ty == ProposalType.Contract) {
            startTime = block.timestamp;
            endTime = startTime + rule.contractVotingDuration;
        } else {
            if (rule.communityVotingDuration == 0) {
                if (startTime == 0) {
                    startTime = block.timestamp;
                }
                require(startTime < endTime, "startTime < endTime");
            } else {
                if (startTime == 0) {
                    startTime = block.timestamp;
                }
                endTime = startTime + rule.communityVotingDuration;
            }
        }
        proposalMap[id] = Proposal(id, ty, msg.sender, title, content, startTime, endTime,
            rule.minimumVote, rule.minimumValidVotes, rule.minimumCreateProposal, ProposalStatus.Review, data);
        for (uint i = 0; i < options.length; i++) {
            optionsMap[id].push(options[i]);
        }
        emit CreateProposal(id, uint(ty), msg.sender, address(this), rule.minimumCreateProposal, startTime, endTime);
    }

    function getProposalById(uint id) public view returns (Proposal memory p){
        p = proposalMap[id];
        p.status = getProposalStatus(p, id);
        return p;
    }

    function cancelProposal(uint id) public {
        Proposal storage pro = proposalMap[id];
        require(pro.creator == msg.sender, "invalid caller");
        require(pro.status == ProposalStatus.Review || pro.status == ProposalStatus.Active, "invalid status");
        require(block.timestamp < pro.endTime, "has end");
        pro.status = ProposalStatus.Cancel;
        emit CancelProposal(id, address(this), msg.sender, pro.minimumCreateProposal);
    }

    // 投票
    function vote(uint id, uint optionIndex, VoteInfo calldata voteInfo, bytes calldata signature) public {
        require(voteInfo.sigType == SigType.Vote, "invalid SigType");
        require(verifyVote(voteInfo, signature), "invalid vote parameter");
        existedNonce[msg.sender][voteInfo.nonce] = true;
        Proposal storage pro = proposalMap[id];
        Option[] storage options = optionsMap[id];
        require(optionIndex < options.length, "invalid index");
        require(block.timestamp >= pro.startTime, "not start");
        require(block.timestamp < pro.endTime, "has end");
        require(voteResults[msg.sender][id].amount == 0, "voted");
        require(pro.status == ProposalStatus.Active || pro.status == ProposalStatus.Review, "invalid status");
        if (pro.status == ProposalStatus.Review) {
            pro.status = ProposalStatus.Active;
        }
        require(voteInfo.weight >= pro.minimumVote, "Insufficient weight");
        uint oldAmount = options[optionIndex].amount;
        voteResults[msg.sender][id] = VoteResult(id, optionIndex, voteInfo.weight);
        options[optionIndex].amount = oldAmount + voteInfo.weight;
        emit Vote(id, msg.sender, voteInfo.weight, optionIndex);
    }

    function executeProposal(uint id) public {
        Proposal storage pro = proposalMap[id];
        require(block.timestamp > pro.endTime, "not end");
        require(pro.proType == ProposalType.Contract, "not contract proposal");
        require(pro.status == ProposalStatus.Active || pro.status == ProposalStatus.Success, "invalid status");
        Option[] storage options = optionsMap[id];
        if (pro.status == ProposalStatus.Active) {
            if (options[0].amount + options[1].amount >= pro.minimumValidVotes &&
                options[0].amount > options[1].amount) {
                pro.status = ProposalStatus.Success;
            } else {
                pro.status = ProposalStatus.Failed;
            }
        }
        if (pro.status == ProposalStatus.Success) {
            pro.status = ProposalStatus.Executed;
            daoAddr.functionCall(pro.data);
        }
        emit ExecuteProposal(id, pro.status == ProposalStatus.Success);
    }

    function verifyVote(VoteInfo calldata voteInfo, bytes calldata signature) public view returns (bool) {
        if (voteInfo.chainId != chainId || voteInfo.user != msg.sender
        || voteInfo.voting != address(this) || existedNonce[msg.sender][voteInfo.nonce]) {
            return false;
        }
        bytes32 h = hash(voteInfo);
        address signer = h.recover(signature);
        if (signer == address(0)) {
            return false;
        }
        return verifyTrustedAddr(signer);
    }

    function verifyTrustedAddr(address signer) internal view returns (bool){
        for (uint i = 0; i < trustedAddr.length; i++) {
            if (trustedAddr[i] == signer) {
                return true;
            }
        }
        return false;
    }

    function hash(VoteInfo calldata voteInfo) public pure returns (bytes32) {
        bytes32 h = keccak256(abi.encodePacked(voteInfo.chainId, voteInfo.user,
            voteInfo.weight, voteInfo.voting, voteInfo.nonce, uint(voteInfo.sigType)));
        return h.toEthSignedMessageHash();
    }

    function convertBytesToBytes4(bytes memory inBytes) pure public returns (bytes4 outBytes4) {
        if (inBytes.length < 4) {
            return 0x0;
        }
        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }

    function getNextId() view internal returns (uint) {
        return curId + 1;
    }

    function increaseId() internal {
        curId = curId + 1;
    }

    //Query proposal status
    function getProposalStatus(Proposal memory p, uint id) internal view returns (ProposalStatus) {
        if (p.status == ProposalStatus.Cancel || p.status == ProposalStatus.Success || p.status == ProposalStatus.Failed || p.status == ProposalStatus.Executed) {
            return p.status;
        } else {
            if (block.timestamp < p.startTime) {
                return p.status;
            } else if (block.timestamp >= p.startTime && block.timestamp < p.endTime) {
                return ProposalStatus.Active;
            } else {
                return _updateStatus(p, id);
            }
        }
    }

    function _updateStatus(Proposal memory pro, uint id) view internal returns (ProposalStatus){
        Option[] storage options = optionsMap[id];
        if (pro.proType == ProposalType.Contract) {
            if (options[0].amount + options[1].amount >= pro.minimumValidVotes &&
                options[0].amount > options[1].amount) {
                return ProposalStatus.Success;
            } else {
                return ProposalStatus.Failed;
            }
        } else if (pro.proType == ProposalType.Community) {
            uint total;
            for (uint i = 0; i < options.length; i++) {
                total = total + options[i].amount;
            }
            if (total >= pro.minimumValidVotes) {
                return ProposalStatus.Success;
            } else {
                return ProposalStatus.Failed;
            }
        } else {
            revert("invalid proposal type");
        }
    }

    function copyAddr(address[] memory from, address[] storage to) internal {
        for (uint i = 0; i < from.length; i++) {
            to.push(from[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface IDAOInterface {

    struct DAOBasic {
        string daoName;
        string daoDesc;
        string website;
        string twitter;
        string discord;
        string tokenName;
        string tokenSymbol;
        string tokenLogo;
        uint tokenSupply;
        uint8 tokenDecimal;
        bool transfersEnabled;
    }

    struct ReservedTokens {
        address to;
        uint amount;
        uint lockDate;
    }

    struct PrivateSale {
        address to;
        uint amount; //daoToken的数量
        uint price;
    }

    struct PublicSale {
        uint amount;
        uint price;
        uint startTime;
        uint endTime;
        uint pledgeLimitMin;// Crowdfunding minimum
        uint pledgeLimitMax;//Crowdfunding maximum
    }

    struct Distribution {
        ReservedTokens[] reserves;
        PrivateSale[] priSales;
        PublicSale pubSale;
        address receiveToken;
        string introduction;
    }

    struct DAORule {
        uint minimumVote;
        uint minimumCreateProposal;
        uint minimumValidVotes;// 最小有效票数
        uint communityVotingDuration;
        uint contractVotingDuration;
        string content;
    }

    function initialize(DAOBasic memory basic, Distribution memory dis, DAORule memory rule,
        address _daoToken, address _voting) external;

    function getDaoRule() view external returns (DAORule memory);

    function getDaoToken() view external returns (address);
}


interface IDaoVotingInterface {
    function updateReserveLockDate(address user, uint date) external;

    function updateDaoRule(IDAOInterface.DAORule memory _rule) external;

    function withdrawToken(address token, address to, uint amount) external;
}

interface IDaoExternalVotingInterface {
    function updateDaoRule(IDAOInterface.DAORule memory _rule) external;
}

interface IDAOExternalInterface {

    struct DAOBasic {
        string daoName;
        string daoDesc;
        string website;
        string twitter;
        string discord;
        string tokenLogo;
    }

    function initialize(IDAOExternalInterface.DAOBasic memory basic, IDAOInterface.DAORule memory rule,
        address _daoToken, address _voting) external;

    function getDaoRule() view external returns (IDAOInterface.DAORule memory);

    function getDaoToken() view external returns (address);
}


interface IDAOCrossGovInterface {

    struct DAOBasic {
        string name;
        uint chainId;
        address contractAddress;
        string daoDesc;
        string website;
        string twitter;
        string discord;
        string tokenLogo;
    }

    struct DAORule {
        uint minimumVote;
        uint minimumCreateProposal;
        uint minimumValidVotes;// 最小有效票数
        uint communityVotingDuration;
        uint contractVotingDuration;
        string content;
    }


    function initialize(IDAOCrossGovInterface.DAOBasic memory basic, IDAOCrossGovInterface.DAORule memory rule,
        address _voting) external;

    function getDaoRule() view external returns (IDAOCrossGovInterface.DAORule memory);

    function updateDaoRule(IDAOCrossGovInterface.DAORule memory _rule) external;

    function getDaoToken() pure external returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface IVotingInterface {
    struct Proposal {
        uint id;
        ProposalType proType;
        address creator;
        string title;
        string content;
        uint startTime;
        uint endTime;
        uint blkHeight;
        uint minimumVote;
        uint minimumValidVotes;// 最小有效票数
        uint minimumCreateProposal;
        ProposalStatus status;
        bytes data;// executeScript
    }
    enum ProposalType {
        Community, // community proposal
        Contract
    }
    enum ProposalStatus {
        Review,
        Active,
        Failed,
        Success,
        Cancel,
        Executed // 已执行
    }
    function initialize(address dao) external;
}


interface ICrossGovVotingInterface {
    enum ProposalType {
        Community, // community proposal
        Contract
    }

    struct Proposal {
        uint id;
        ProposalType proType;
        address creator;
        string title;
        string content;
        uint startTime;
        uint endTime;
        uint minimumVote;
        uint minimumValidVotes;// 最小有效票数
        uint minimumCreateProposal;
        ProposalStatus status;
        bytes data;
    }

    enum ProposalStatus {
        Review,
        Active,
        Failed,
        Success,
        Cancel,
        Executed // 已执行
    }
    function initialize(address dao, uint chainId, address[] calldata _trustedAddr) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface TokenInterface {
    function initialize(string memory name_, string memory symbol_,
        string memory logo_, uint totalSupply_, uint8 decimals_,
        bool _transfersEnabled, address to) external;

    //if external dao, the second args is snapshotId
    function balanceOfAt(address _user, uint _blockNumber) external view returns (uint);
}

interface TokenSnapshotInterface {

    //if external dao, the second args is snapshotId
    function balanceOfAt(address _user, uint _blockNumber) external view returns (uint);

    function snapshot() external returns (uint);

    function getCurrentSnapshotId() external view returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {ContextUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IDAOInterface.sol";
import "./interfaces/IVotingInterface.sol";
import "./lib/UniversalERC20.sol";
import "./interfaces/ITokenInterface.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";

contract Voting is ContextUpgradeable, IVotingInterface {
    using UniversalERC20 for IERC20;
    using Address for address;

    struct Option {
        string name;
        uint amount;
    }

    struct VoteResult {
        uint id;
        uint optionIndex;
        uint amount;
    }

    uint public curId;
    address public daoAddr;
    mapping(uint => Proposal) internal proposalMap; // id => Proposal
    mapping(address => mapping(uint => VoteResult)) public voteResults;//address => proposalId => VoteResult
    mapping(uint => Option[]) public optionsMap;//proposalId => Option
    mapping(uint => bool) public claimed;// 记录已经claim的信息;

    event CreateProposal(uint indexed id, address from, address to, uint amount, uint startTime, uint endTime, address daoToken);
    event CancelProposal(uint indexed id, address from, address to, uint amount, address daoToken);
    event Vote(uint indexed id, address indexed user, uint amount, uint optionIndex);
    event ResolveVotingResult(uint indexed id, uint res);
    event ExecuteProposal(uint indexed id, bool isSuccess);
    event ClaimToken(uint indexed id, address from, address to, uint amount, address daoToken);

    function initialize(address dao) initializer override public {
        daoAddr = dao;
        __Context_init();
    }

    function getOptionsById(uint id) public view returns (Option[] memory) {
        return optionsMap[id];
    }

    //create Contract proposal
    function createContractProposal(string calldata title, string calldata content, bytes memory data) public {
        Option[] memory options = new Option[](2);
        options[0] = Option("approve", 0);
        options[1] = Option("disapprove", 0);
        createProposal(1, title, content, 0, 0, options, data);
    }
    //CREATE COMMUNITY Proposal
    function createCommunityProposal(string calldata title, string calldata content,
        uint startTime, uint endTime, string[] calldata _options) public {
        Option[] memory options = new Option[](_options.length);
        for (uint i = 0; i < _options.length; i++) {
            options[i] = Option(_options[i], 0);
        }
        createProposal(0, title, content, startTime, endTime, options, new bytes(0));
    }

    function createProposal(uint ty, string memory title, string memory content,
        uint startTime, uint endTime, Option[] memory options, bytes memory data) internal {
        if (ty == uint(ProposalType.Contract)) {
            require(data.length >= 4, "invalid data");
            require(IERC165Upgradeable(daoAddr).supportsInterface(convertBytesToBytes4(data)), "not supported method");
        }
        IDAOInterface.DAORule memory rule = IDAOInterface(daoAddr).getDaoRule();
        address daoToken = IDAOInterface(daoAddr).getDaoToken();
        IERC20(daoToken).universalTransferFrom(msg.sender, address(this), rule.minimumCreateProposal);
        uint id = getNextId();
        increaseId();
        if (ty == uint(ProposalType.Contract)) {
            startTime = block.timestamp;
            endTime = startTime + rule.contractVotingDuration;
        } else {
            if (rule.communityVotingDuration == 0) {
                if (startTime == 0) {
                    startTime = block.timestamp;
                }
                require(startTime < endTime, "startTime < endTime");
            } else {
                if (startTime == 0) {
                    startTime = block.timestamp;
                }
                endTime = startTime + rule.communityVotingDuration;
            }
        }
        proposalMap[id] = Proposal(id, ProposalType(ty), msg.sender, title, content, startTime, endTime, block.number,
            rule.minimumVote, rule.minimumValidVotes, rule.minimumCreateProposal, ProposalStatus.Review, data);
        for (uint i = 0; i < options.length; i++) {
            optionsMap[id].push(options[i]);
        }
        emit CreateProposal(id, msg.sender, address(this), rule.minimumCreateProposal, startTime, endTime, daoToken);
    }

    function getProposalById(uint id) public view returns (Proposal memory p){
        p = proposalMap[id];
        p.status = getProposalStatus(p, id);
        return p;
    }

    function cancelProposal(uint id) public {
        Proposal storage pro = proposalMap[id];
        require(pro.creator == msg.sender, "invalid caller");
        require(pro.status == ProposalStatus.Review || pro.status == ProposalStatus.Active, "invalid status");
        require(!claimed[id], "claimed");
        require(block.timestamp < pro.endTime, "has end");
        pro.status = ProposalStatus.Cancel;
        address daoToken = IDAOInterface(daoAddr).getDaoToken();
        claimed[id] = true;
        IERC20(daoToken).universalTransfer(payable(msg.sender), pro.minimumCreateProposal);
        emit CancelProposal(id, address(this), msg.sender, pro.minimumCreateProposal, daoToken);
    }

    // 提取 质押的token
    function claimToken(uint id) public {
        Proposal storage pro = proposalMap[id];
        ProposalStatus status = getProposalStatus(pro, id);
        require(!claimed[id], "claimed");
        require(status == ProposalStatus.Success || status == ProposalStatus.Failed || status == ProposalStatus.Executed, "can not claim token");
        address daoToken = IDAOInterface(daoAddr).getDaoToken();
        claimed[id] = true;
        IERC20(daoToken).universalTransfer(payable(pro.creator), pro.minimumCreateProposal);
        emit ClaimToken(id, address(this), msg.sender, pro.minimumCreateProposal, daoToken);
    }

    // 投票
    function vote(uint id, uint optionIndex) public {
        Proposal storage pro = proposalMap[id];
        Option[] storage options = optionsMap[id];
        require(block.timestamp >= pro.startTime, "not start");
        require(block.timestamp < pro.endTime, "has end");
        require(voteResults[msg.sender][id].amount == 0, "voted");
        require(pro.status == ProposalStatus.Active || pro.status == ProposalStatus.Review, "invalid status");
        if (pro.status == ProposalStatus.Review) {
            pro.status = ProposalStatus.Active;
        }
        address daoToken = IDAOInterface(daoAddr).getDaoToken();
        uint bal = TokenInterface(daoToken).balanceOfAt(msg.sender, pro.blkHeight);
        require(bal >= pro.minimumVote, "Insufficient balance");
        uint oldAmount = options[optionIndex].amount;
        voteResults[msg.sender][id] = VoteResult(id, optionIndex, bal);
        options[optionIndex].amount = oldAmount + bal;
        emit Vote(id, msg.sender, bal, optionIndex);
    }

    function executeProposal(uint id) public {
        Proposal storage pro = proposalMap[id];
        require(block.timestamp > pro.endTime, "has not end");
        require(pro.proType == ProposalType.Contract, "must be contract proposal");
        require(pro.status == ProposalStatus.Active || pro.status == ProposalStatus.Success, "invalid status");
        Option[] storage options = optionsMap[id];
        if (pro.status == ProposalStatus.Active) {
            if (options[0].amount + options[1].amount >= pro.minimumValidVotes &&
                options[0].amount > options[1].amount) {
                pro.status = ProposalStatus.Success;
            } else {
                pro.status = ProposalStatus.Failed;
            }
        }
        if (pro.status == ProposalStatus.Success) {
            pro.status = ProposalStatus.Executed;
            daoAddr.functionCall(pro.data);
            emit ExecuteProposal(id, true);
        } else {
            emit ExecuteProposal(id, false);
        }
    }

    function convertBytesToBytes4(bytes memory inBytes) pure public returns (bytes4 outBytes4) {
        if (inBytes.length < 4) {
            return 0x0;
        }
        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }

    function getNextId() view internal returns (uint) {
        return curId + 1;
    }

    function increaseId() internal {
        curId = curId + 1;
    }

    //Query proposal status
    function getProposalStatus(Proposal memory p, uint id) internal view returns (ProposalStatus) {
        if (p.status == ProposalStatus.Cancel || p.status == ProposalStatus.Success || p.status == ProposalStatus.Failed || p.status == ProposalStatus.Executed) {
            return p.status;
        } else {
            if (block.timestamp < p.startTime) {
                return p.status;
            } else if (block.timestamp >= p.startTime && block.timestamp < p.endTime) {
                return ProposalStatus.Active;
            } else {
                return _updateStatus(p, id);
            }
        }
    }

    function _updateStatus(Proposal memory pro, uint id) view internal returns (ProposalStatus){
        Option[] storage options = optionsMap[id];
        if (pro.proType == ProposalType.Contract) {
            if (options[0].amount + options[1].amount >= pro.minimumValidVotes &&
                options[0].amount > options[1].amount) {
                return ProposalStatus.Success;
            } else {
                return ProposalStatus.Failed;
            }
        } else if (pro.proType == ProposalType.Community) {
            uint total;
            for (uint i = 0; i < options.length; i++) {
                total = total + options[i].amount;
            }
            if (total >= pro.minimumValidVotes) {
                return ProposalStatus.Success;
            } else {
                return ProposalStatus.Failed;
            }
        } else {
            revert("invalid proposal type");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library UniversalERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 internal constant ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 internal constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 internal constant MATIC_ADDRESS = IERC20(0x0000000000000000000000000000000000001010);

    function universalDecimals(
        IERC20 token
    ) internal view returns (uint8) {
        if (isETH(token)) {
            return 18;
        } else {
            return IERC20Metadata(address(token)).decimals();
        }
    }

    function universalTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (isETH(token)) {
                payable(to).transfer(amount);
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    function universalTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }
        if (isETH(token)) {
            require(from == msg.sender && msg.value >= amount, "Wrong useage of ETH.universalTransferFrom()");
            if (to != address(this)) {
                payable(to).transfer(amount);
            }
            if (msg.value > amount) {
                // return the remainder
                payable(msg.sender).transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        require(!isETH(token), "Approve called on ETH");

        if (amount == 0) {
            token.approve(to, 0);
        } else {
            uint256 allowance = token.allowance(address(this), to);
            if (allowance < amount) {
                if (allowance > 0) {
                    token.approve(to, 0);
                }
                token.safeApprove(to, amount);
            }
        }
    }

    function universalBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return
        address(token) == address(ETH_ADDRESS) ||
        address(token) == address(MATIC_ADDRESS) ||
        address(token) == address(ZERO_ADDRESS);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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