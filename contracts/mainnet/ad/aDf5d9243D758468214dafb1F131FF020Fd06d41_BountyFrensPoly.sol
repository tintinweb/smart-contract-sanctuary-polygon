// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "./Lib/Frens.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IAlphaFrens {
    function updateTraitValue(uint _tokenId, uint8 _newValue, uint8 _position) external;
    function updateTraitName(uint _tokenId, string memory _newValue, uint8 _position) external;
}

contract BountyFrensPoly is ReentrancyGuard{
    IAlphaFrens public alphaFrens;
    uint private bountyId = 1;

    struct Reward {
        uint8 rewardType;
        uint8 rewardValue;
        string newNameTrait;
        uint256 rewardEther;
    }

    struct Bounty {
        address completedBy;
        uint8 isCompleted;
        Reward reward;
        string bountyName;
    }

    mapping(uint => Bounty) private bounties;
    mapping(address => bool ) private owners;

    event CompletedBounty (uint indexed bountyId, address indexed completedBy, uint amountPayed);
    event CreatedBounty (uint indexed bountyId, address indexed createdBy, string bountyName, uint256 rewardInEther);
    event UpdateBountyRewardType (uint indexed bountyId, uint8 rewardType);
    event UpdateBountyRewardValue (uint indexed bountyId, uint8 rewardValue);
    event UpdateBountyRewardNameTrait(uint indexed bountyId, string nameTrait);
    event UpdateBountyRewardEther (uint indexed bountyId, uint256 rewardEther);
    event UpdateBountyRewardImageURI (uint indexed bountyId, string imageURI);
    event DeleteBounty(uint indexed bountyId);

    modifier onlyOwners {
        require(owners[msg.sender], "BF: NOT_OWNER");
        _;
    }

    function createBounty(string calldata bountyName, uint8 rewardType, uint8 rewardValue, string calldata newNameTrait)
        external
        payable
        onlyOwners
    {
        emit CreatedBounty(bountyId, msg.sender, bountyName, msg.value);

        bounties[bountyId] = Bounty(address(1), 1,
            Reward(
                rewardType,
                rewardValue,
                newNameTrait,
                msg.value), bountyName
            );

        unchecked {
            bountyId++;
        }

        return;
    }

    function setAlphaFrensContract(address afcontract)
        public
        onlyOwners
    {
        alphaFrens = IAlphaFrens(afcontract);
    }

    function updateBountyName(uint id, string calldata newBountyName)
        external
        onlyOwners
    {
        bounties[id].bountyName = newBountyName;
    }

    function updateBountyRewardNameTrait(uint id, string calldata newNameTrait)
        external
        onlyOwners
    {
        emit UpdateBountyRewardNameTrait(id, newNameTrait);
        bounties[id].reward.newNameTrait = newNameTrait;
    }

    function updateBountyRewardType(uint id, uint8 newRewardType)
        external
        onlyOwners
    {
        emit UpdateBountyRewardType(id, newRewardType);
        bounties[id].reward.rewardType = newRewardType;
    }

    function updateBountyRewardValue(uint id, uint8 newRewardValue)
        external
        onlyOwners
    {
        emit UpdateBountyRewardValue(id, newRewardValue);
        bounties[id].reward.rewardValue = newRewardValue;
    }

    function deleteBounty(uint id)
        external
        onlyOwners
    {
        unchecked {
            bountyId--;
        }
        emit DeleteBounty(id);
        delete bounties[id];
    }

    function addEtherToBounty(uint id)
        external
        payable
        nonReentrant
    {
        uint256 newReward = bounties[id].reward.rewardEther + msg.value;
        emit UpdateBountyRewardEther(id, newReward);
        bounties[id].reward.rewardEther = newReward;
    }

    function completeBounty(uint id, address completedBy, uint tokenId)
        external
        payable
        nonReentrant
        onlyOwners
    {
        require(
            bounties[id].isCompleted == 1,
            "BF: ALREADY_COMPLETED"
        );
        require(
            !FrensLib.isEmptyString(bytes(bounties[id].bountyName)),
            "BF: BOUNTY_NOT_DEFINED"
        );

        bounties[id].isCompleted = 2;
        bounties[id].completedBy = completedBy;
        uint ethReward =  bounties[id].reward.rewardEther;
        string memory newName = bounties[id].reward.newNameTrait;

        emit CompletedBounty (id, completedBy, ethReward);

        if(!FrensLib.isEmptyString(bytes(newName)))
            alphaFrens.updateTraitName(tokenId, bounties[id].reward.newNameTrait, bounties[id].reward.rewardType);

        if(bounties[id].reward.rewardValue != 0)
            alphaFrens.updateTraitValue(tokenId, bounties[id].reward.rewardValue, bounties[id].reward.rewardType);

        //emits the rewards
        if(ethReward > 0){
            require(
                address(this).balance >= ethReward,
                "BF: NOT_ENOUGH_ETHER"
            );
            require(
                completedBy != address(0),
                "BF: NOT_0_ADDRESS"
            );

            bounties[id].reward.rewardEther = 0;
            //solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = payable(completedBy).call{value: ethReward}("");

            require(
                success,
                "BF: TRANSACTION_FAILED"
            );
        }

        return;
    }

    function getBountyRewards(uint id)
        external
        view
        returns(Reward memory)
    {
        return bounties[id].reward;
    }

    function getBounty(uint id)
        external
        view
        returns(Bounty memory)
    {
        return bounties[id];
    }

    function getEthInContract()
        external
        onlyOwners
        view
        returns(uint)
    {
        return address(this).balance;
    }

    function withdrawEtherFromContract()
        external
        payable
        onlyOwners
    {
        require(
            address(this).balance > 0,
            "BF: NOT_ENOUGH_ETHER"
        );
        //solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");

        require(
            success,
            "BF: FAILED_TRANSACTION"
        );
    }

    function addOwner(address _owner) external onlyOwners {
        owners[_owner] = true;
    }

    constructor () {
        owners[msg.sender] = true;
        setAlphaFrensContract(0x11309E0CD831beA0550aB39A9C5A28Bdb8AD1Cc7);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
library FrensLib {
    /* solhint-disable */
    string internal constant TABLE_ENCODE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data)
        internal
        pure
        returns (string memory)
    {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value)
        internal
        pure
        returns (string memory)
    {
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

    function isEmptyString(bytes memory str)
        internal
        pure
        returns(bool)
    {
        if(str.length == 0) return true;

        return false;
    }

    function stringToBytes5(string memory source)
        internal
        pure
        returns (bytes5 result)
    {
        bytes memory _source = abi.encodePacked(source);
        if(_source.length == 0) revert();
        assembly {
            result := mload(add(_source, 32))
        }
    }

    function convertToIPFSLink(bytes memory newImageURI, uint tokenId, string memory extension)
        internal
        pure
        returns(bytes memory)
    {
        return abi.encodePacked(newImageURI, toString(tokenId), extension);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}