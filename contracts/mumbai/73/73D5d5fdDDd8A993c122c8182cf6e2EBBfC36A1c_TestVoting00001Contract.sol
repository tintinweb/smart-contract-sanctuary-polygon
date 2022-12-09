// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IMainNFTContract {
    function getAddressBalance(address _address) external view returns (uint);
}

interface ISubNFTContract {
    function getAddressBalance(address _address) external view returns (uint);
}

contract TestVoting00001Contract is Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter public totalVoteCount;

    string public subject = "Who will be the new president?";
    string public desciption = "In this elections, candidates are elected directly by popular vote.";

    mapping(uint256 => address) nftAdresses;

    uint256 private optionsCount = 5;
    mapping(uint256 => string) options;

    mapping(uint256 => Counters.Counter) optionsVoteCount;

    mapping(uint256 => uint256) equalMostVotedOptionsId;
    Counters.Counter equalMostVotedOptionsIdCount;

    mapping(address => uint256) addressSelectedOptionId;
    mapping(address => Counters.Counter) addressVoteCount;

    string private result = "";
    uint256 private resultOptionId = 0;
    bool public resultState = false;

    uint256 public startDate = 1670150430;
    uint256 public endDate = 1670150430;

    bool public voteState = true;

    uint256 public price = 0.01 ether;

    address public founder1 = 0xD099723478bDc2AF9c3C34f89C246A8194BD5d49;
    address public founder2 = 0x34134A4E31850d56783fC2ea45E4Fc6c474E0342;
    address public communityAndPartners = 0xcD49c32608173AD2DAF45471e2f8661655e237A5;
    address public treasury = 0xAf53fC42BcBC2a85bD7a865C6E8a43be3c1cb943;

    constructor() {
        options[0] = "";
        options[1] = "James Smith";
        options[2] = "Robert Hernandez";
        options[3] = "Maria Garcia";
        options[4] = "James Johnson";
        options[5] = "Wilson Martinez";

        nftAdresses[0] = 0x4eF9868ab3bafd4992F371793021B00bE63EB3A6;
        nftAdresses[1] = 0x6c094d7A9eb1313b35ACCC981682ba1aE3C21932;
    }

    function vote(uint256 optionId) public payable {
        require(voteState == true, "Voting haven't start yet.");
        require(addressVoteCount[msg.sender].current() < 1, "This wallet address already voted");

        uint256 addressBalanceNFTName1 = IMainNFTContract(nftAdresses[0]).getAddressBalance(msg.sender);
        uint256 addressBalanceNFTName2 = ISubNFTContract(nftAdresses[1]).getAddressBalance(msg.sender);

        require(addressBalanceNFTName1 > 0 || addressBalanceNFTName2 > 0, "This wallet address cannot join the voting");

        require(optionId > 0 && optionId < 5, "Option with this option id doesn't exist.");
        
        require(msg.value >= price, "Insufficient funds.");

        totalVoteCount.increment();
        optionsVoteCount[optionId].increment();
        addressVoteCount[msg.sender].increment();
        addressSelectedOptionId[msg.sender] = optionId;
    }

    function getAddressVote(address _address) public view returns (string memory)  {
        require(addressVoteCount[_address].current() > 0, "This wallet address didn't join the voting yet");
        
        string memory currentAddressSelectedOption = options[addressSelectedOptionId[_address]];
        return bytes(currentAddressSelectedOption).length > 0 ? string(abi.encodePacked(currentAddressSelectedOption)) : "";
    }

    function calculateResult() public onlyOwner {
        require(totalVoteCount.current() > 0, "Result cannot be calculated because there is zero vote now.");
        
        uint256 mostVotedOptionId = 0;

        for(uint256 i = 0; i < optionsCount; i++) {
            if(optionsVoteCount[i].current() >= optionsVoteCount[mostVotedOptionId].current()) {
                mostVotedOptionId = i;

                if(i != mostVotedOptionId && optionsVoteCount[i].current() == optionsVoteCount[mostVotedOptionId].current()) {
                    equalMostVotedOptionsId[i] = i;
                    equalMostVotedOptionsIdCount.increment();
                }
            }
        }

        if(equalMostVotedOptionsIdCount.current() > 0) {
            uint256 randomIndex = uint256(blockhash(block.number - 1)) % equalMostVotedOptionsIdCount.current();
            mostVotedOptionId = equalMostVotedOptionsId[randomIndex];
        }

        result = options[mostVotedOptionId];
        resultOptionId = mostVotedOptionId;
    }

    function updatePrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function updateVoteState(bool newVoteState) public onlyOwner {
        voteState = newVoteState;
    }

    function updateResultState(bool newResultState) public onlyOwner {
        resultState = newResultState;
    }

    function updateStartDate(uint256 newStartDate) public onlyOwner {
        startDate = newStartDate;
    }

    function updateEndDate(uint256 newEndDate) public onlyOwner {
        endDate = newEndDate;
    }

    function showResult() public view returns(string memory) {
        require(resultState == true, "The result hasn't announced yet.");
        return bytes(result).length > 0 ? string(abi.encodePacked(result)) : "";
    }

    function showResultOptionID() public view returns(uint256) {
        require(resultState == true, "The result hasn't announced yet.");
        return resultOptionId;
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Not enough balance.");

        (bool successFounder1, ) = payable(founder1).call{value: ((balance * 250) / 1000)}("");
        require(successFounder1, "Transfer failed.");

        (bool successFounder2, ) = payable(founder2).call{value: ((balance * 250) / 1000)}("");
        require(successFounder2, "Transfer failed.");

        (bool successCommunityAndPartners, ) = payable(communityAndPartners).call{value: ((balance * 250) / 1000)}("");
        require(successCommunityAndPartners, "Transfer failed.");

        (bool successTreasury, ) = payable(treasury).call{value: ((balance * 250) / 1000)}("");
        require(successTreasury, "Transfer failed.");

        (bool successOwner, ) = payable(msg.sender).call{value: (address(this).balance)}("");
        require(successOwner, "Transfer failed.");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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