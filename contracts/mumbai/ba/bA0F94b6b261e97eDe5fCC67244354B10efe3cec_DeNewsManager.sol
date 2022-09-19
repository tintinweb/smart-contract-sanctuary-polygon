// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ByteHasher} from "../libraries/ByteHasher.sol";
import {IWorldID} from "../interfaces/IWorldID.sol";
import "../interfaces/IDeNewsToken.sol";
import "../interfaces/IDeNewsVoting.sol";

contract DeNewsManager is Ownable, IERC721Receiver {
    IDeNewsToken DeNewsToken;
    IDeNewsVoting DeNewsVoting;
    IWorldID worldId;

    using ByteHasher for bytes;

    uint256 public fakeHuntersDeposit;
    uint256 internal constant groupId = 1;

    address public addressDeNewsMediaContract;

    struct fakeHunterProfile {
        bool fakeHunterAccreditation;
        int256 fakeHunterRating;
    }

    struct votingCard {
        uint256 lockedAmount;
        uint256 lockedAmountWithReward;
        bytes32 voteHash;
        bool pending;
    }

    mapping(address => uint256) private depositBalance;
    mapping(address => mapping(uint256 => votingCard))
        private participationInVoting;
    mapping(address => fakeHunterProfile) private fakeHuntersArchive;
    mapping(uint256 => bool) private nullifierHashes;
    mapping(address => bool) private humanVerification;

    function setDeNewsMediaContract(address _addressMediaContract)
        external
        onlyOwner
    {
        addressDeNewsMediaContract = _addressMediaContract;
    }

    function setDeNewsVotingContract(address _addressDeNewsVotingContract)
        external
        onlyOwner
    {
        DeNewsVoting = IDeNewsVoting(_addressDeNewsVotingContract);
    }

    function setDeNewsTokenContract(address _DeNT) external onlyOwner {
        DeNewsToken = IDeNewsToken(_DeNT);
    }

    function setWorldIdContract(address _addressWorldId) external onlyOwner {
        worldId = IWorldID(_addressWorldId);
    }

    function setFakeHunterDeposit(uint256 _amount) public onlyOwner {
        fakeHuntersDeposit = _amount;
    }

    function humanVerify(
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public payable {
        require(
            humanVerification[msg.sender] == false,
            "You already verified!"
        );
        require(
            nullifierHashes[nullifierHash] == false,
            "Nullifier Hash already used!"
        );
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(msg.sender).hashToField(),
            nullifierHash,
            abi.encodePacked(address(this)).hashToField(),
            proof
        );
        nullifierHashes[nullifierHash] = true;
        humanVerification[msg.sender] = true;
    }

    function checkHumanVerify(address _user) public view returns (bool) {
        return humanVerification[_user];
    }

    function fakeHuntersRegistration(uint256 _amount) public {
        require(_amount >= fakeHuntersDeposit, "You don't have enough tokens!");
        require(
            fakeHuntersArchive[msg.sender].fakeHunterRating == 0,
            "You are already registred!"
        );
        deposit(_amount);
        fakeHunterProfile storage newFakeHunter = fakeHuntersArchive[
            msg.sender
        ];
        newFakeHunter.fakeHunterAccreditation = true;
        newFakeHunter.fakeHunterRating = 100;
    }

    function fakeHuntersInfo(address _from)
        external
        view
        returns (bool, int256)
    {
        return (
            fakeHuntersArchive[_from].fakeHunterAccreditation,
            fakeHuntersArchive[_from].fakeHunterRating
        );
    }

    function changeRatingFakeHunter(address _address, int256 delta) external {
        require(msg.sender == address(DeNewsVoting), "Only contract!");
        fakeHuntersArchive[_address].fakeHunterRating += delta;
    }

    function blockFakeHunter(address _fakeHunter) public onlyOwner {
        fakeHuntersArchive[_fakeHunter].fakeHunterAccreditation = false;
    }

    function dataOfVote(
        address _voter,
        uint256 _ballotID,
        uint256 _lockedAmount,
        uint256 _lockedAmountWithReward,
        bytes32 _voteHash
    ) public {
        require(msg.sender == address(DeNewsVoting), "You don't have access!");
        depositBalance[_voter] -= _lockedAmount;
        votingCard storage newVotingCard = participationInVoting[_voter][
            _ballotID
        ];
        newVotingCard.lockedAmount = _lockedAmount;
        newVotingCard.lockedAmountWithReward = _lockedAmountWithReward;
        newVotingCard.voteHash = _voteHash;
        newVotingCard.pending = false;
    }

    function participationInVotingInfo(address _voter, uint256 _ballotID)
        public
        view
        returns (
            uint256,
            uint256,
            bytes32,
            bool
        )
    {
        return (
            participationInVoting[_voter][_ballotID].lockedAmount,
            participationInVoting[_voter][_ballotID].lockedAmountWithReward,
            participationInVoting[_voter][_ballotID].voteHash,
            participationInVoting[_voter][_ballotID].pending
        );
    }

    function deposit(uint256 _amount) public {
        // approve contract
        DeNewsToken.transferFrom(msg.sender, address(this), _amount);
        depositBalance[msg.sender] += _amount;
    }

    function depositInfo(address _user) public view returns (uint256) {
        return depositBalance[_user];
    }

    function withdrawRewards(
        uint256 _ballotID,
        string memory password,
        bool _vote
    ) public {
        (
            ,
            uint256 _voteFor,
            uint256 _voteAgainst,
            ,
            ,
            bool _votingStatus
        ) = DeNewsVoting.votingArchiveInfo(_ballotID);
        require(
            _votingStatus == false,
            "You can view the information only after the end of the voting!"
        );
        require(
            participationInVoting[msg.sender][_ballotID].pending == false,
            "The reward has already been paid!"
        );
        require(
            participationInVoting[msg.sender][_ballotID].voteHash ==
                DeNewsVoting.generateVoteHash(
                    _ballotID,
                    participationInVoting[msg.sender][_ballotID].lockedAmount,
                    _vote,
                    password
                ),
            "The entered data does not match!"
        );
        participationInVoting[msg.sender][_ballotID].pending = true;
        if (_voteFor > _voteAgainst) {
            if (_vote == true) {
                depositBalance[msg.sender] += participationInVoting[msg.sender][
                    _ballotID
                ].lockedAmountWithReward;
            } else {
                depositBalance[msg.sender] += participationInVoting[msg.sender][
                    _ballotID
                ].lockedAmount;
            }
        } else {
            if (_vote == true) {
                depositBalance[msg.sender] += participationInVoting[msg.sender][
                    _ballotID
                ].lockedAmount;
            } else {
                depositBalance[msg.sender] += participationInVoting[msg.sender][
                    _ballotID
                ].lockedAmountWithReward;
            }
        }
        participationInVoting[msg.sender][_ballotID].lockedAmount = 0;
        participationInVoting[msg.sender][_ballotID].lockedAmountWithReward = 0;
        participationInVoting[msg.sender][_ballotID].pending = true;
    }

    function withdraw(uint256 _amount) external {
        require(
            depositBalance[msg.sender] >= _amount,
            "You can't withdraw the specified amount!"
        );
        uint256 _contractBalance = DeNewsToken.balanceOf(address(this));
        if (_amount > _contractBalance) {
            DeNewsToken.mint(address(this), _amount - _contractBalance);
        }
        depositBalance[msg.sender] -= _amount;
        DeNewsToken.transfer(msg.sender, _amount);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IWorldID {
    /// @notice Reverts if the zero-knowledge proof is invalid.
    /// @param root The of the Merkle tree
    /// @param groupId The id of the Semaphore group
    /// @param signalHash A keccak256 hash of the Semaphore signal
    /// @param nullifierHash The nullifier hash
    /// @param externalNullifierHash A keccak256 hash of the external nullifier
    /// @param proof The zero-knowledge proof
    /// @dev  Note that a double-signaling check is not included here, and should be carried by the caller.
    function verifyProof(
        uint256 root,
        uint256 groupId,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof
    ) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library ByteHasher {
    /// @dev Creates a keccak256 hash of a bytestring.
    /// @param value The bytestring to hash
    /// @return The hash of the specified value
    /// @dev `>> 8` makes sure that the result is included in our field
    function hashToField(bytes memory value) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(value))) >> 8;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IDeNewsToken {
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

    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IDeNewsVoting {
    function votingArchiveInfo(uint256 _ballotID)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        );

    function generateVoteHash(
        uint256 _ballotID,
        uint256 _amount,
        bool _vote,
        string memory password
    ) external pure returns (bytes32);
}

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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