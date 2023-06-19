// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/SignatureUtility.sol";

contract VotingCampaign is Ownable, SignatureUtility {
    struct Campaign {
        uint256 startTime;
        uint256 endTime;
        address creator;
        string topic;
        string[] options;
        mapping(string => uint256) votes;
        mapping(address => bool) hasVoted;
    }

    uint public campaignCount;

    mapping(uint256 => Campaign) public campaignsMapping;
    mapping(uint256 => address) public campaignCreators;

    event CampaignCreated(
        uint256 indexed campaignId,
        string topic,
        address creator
    );
    event VoteCast(uint256 indexed campaignId, string option, address voter);

    function createCampaign(
        string calldata _topic,
        string[] memory _options,
        uint256 _duration,
        Sign calldata sig
    ) external onlyVerifiedUser(sig) {
        require(_duration > 0, "Invalid duration");
        uint campaignId = ++campaignCount;
        Campaign storage newCampaign = campaignsMapping[campaignId];

        newCampaign.topic = _topic;
        newCampaign.options = _options;
        newCampaign.startTime = block.timestamp;
        newCampaign.endTime = block.timestamp + _duration;

        campaignCreators[campaignId] = _msgSender();

        emit CampaignCreated(campaignId, _topic, _msgSender());
    }

    function vote(
        uint256 _campaignId,
        string calldata _option,
        Sign calldata sig
    ) external onlyVerifiedUser(sig) {
        require(_campaignId < campaignCount, "Invalid campaign ID");

        Campaign storage campaign = campaignsMapping[_campaignId];
        require(
            block.timestamp >= campaign.startTime &&
                block.timestamp <= campaign.endTime,
            "Voting is not currently active"
        );
        require(
            !campaign.hasVoted[_msgSender()],
            "You have already voted in this campaign"
        );

        bool optionFound = false;
        for (uint256 i = 0; i < campaign.options.length; i++) {
            if (
                keccak256(bytes(campaign.options[i])) ==
                keccak256(bytes(_option))
            ) {
                campaign.votes[_option]++;
                optionFound = true;
                break;
            }
        }

        require(optionFound, "Invalid option");

        campaign.hasVoted[_msgSender()] = true;

        emit VoteCast(_campaignId, _option, _msgSender());
    }

    function getVoteCount(
        uint256 _campaignId,
        string calldata _option
    ) external view returns (uint256) {
        require(_campaignId < campaignCount, "Invalid campaign ID");

        Campaign storage campaign = campaignsMapping[_campaignId];
        require(block.timestamp > campaign.endTime, "Voting is still active");

        return campaign.votes[_option];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/utils/Context.sol";

contract SignatureUtility is Context {
    struct Sign {
        bytes signature;
        uint eat;
        uint nonce;
    }

    mapping(uint => bool) internal _usedNonce;
    address private _signer;
    /**
     * @dev Modifier to only allow an authorized signer to perform minting.
     * @dev This Signer may be different from the Owner.
     * @param sig The signature provided by the signer for authorization.
     */

    modifier onlyVerifiedUser(Sign calldata sig) {
        require(sig.eat > block.timestamp, "Signature Already Expired");
        bytes32 messageHash = getMessageHash(_msgSender(), sig.eat, sig.nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        require(
            recoverSigner(ethSignedMessageHash, sig.signature) == _signer,
            "Unauthorised Signer"
        );
        require(!_usedNonce[sig.nonce], "Invalid Signature");
        _;
    }

    /**
     * @dev Sets the Signer address.
     */
    constructor() {
        _signer = _msgSender();
    }

    /**
     * @dev Recovers the address of the signer given an Ethereum signed message hash and a signature.
     * @param _ethSignedMessageHash The hash of the signed message.
     * @param _signature The signature provided by the signer.
     * @return The address of the signer.
     */
    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /**
     * @dev Splits a signature into its r, s, and v components.
     * @param sig The signature to split.
     * @return r component of the signature.
     * @return s component of the signature.
     * @return v component of the signature.
     */
    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    /**
     * @dev Computes the hash of a message.
     * @param eat Expiring At Timestamp.
     * @return The hash of the message.
     */
    function getMessageHash(
        address addr,
        uint eat,
        uint nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(addr, eat, nonce));
    }

    /**
     * @dev Computes the Ethereum signed message hash for a given message hash.
     * @param _messageHash The message hash to sign.
     * @return The Ethereum signed message hash.
     */
    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) internal pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    /**
     * @dev Internal function allows for changing of signer.
     * @param _newSigner Address of the New Signer
     */
    function _setSigner(address _newSigner) internal virtual {
        _signer = _newSigner;
    }

    /**
     * @dev Getter for Signer. Fashioned after Openzeppelin's owner() method of Ownable contract.
     */
    function signer() internal view returns (address) {
        return _signer;
    }
}