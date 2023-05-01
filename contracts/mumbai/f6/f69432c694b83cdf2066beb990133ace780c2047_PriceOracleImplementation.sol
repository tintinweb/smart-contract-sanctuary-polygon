/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

/**
 *Submitted for verification at polygonscan.com on 2023-04-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringToBytes32 {
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        // Ensure that the source string is not longer than 32 bytes
        require(tempEmptyStringTest.length <= 32, "Source string is too long.");

        assembly {
            result := mload(add(source, 32))
        }
    }
}

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}

interface PriceOracle {
    /**
     * @dev Returns the price to register.
     * @param condition keccak256 multiple conditions, like payment token address, duration, length, etc.
     * @return The price of this registration.
     */
    function getPrice(bytes32 tld, bytes32 condition) external view returns(uint);

    /**
     * @dev Returns the payment token addresses according to a specific tld.
     * @param tld keccak256 tld.
     * @return The payment token addresses.
     */
    function getSupportedPayment(bytes32 tld) external view returns(address[] memory);

    /**
     * @dev Returns the permanent ownership status of subnode belonged to a tld.
     * @param tld keccak256 tld.
     * @return The permanent ownership status of subnode belonged to a tld
     */
    function permanentOwnershipOfSubnode(bytes32 tld) external view returns(bool);

    function receivingAddress(bytes32 tld) external view returns(address);
}

contract PriceOracleImplementation {
    using StringUtils for string;

    address public registryController;
    mapping(address=>bool) public whitelist;
    bool whitelistEnabled;

    struct TldOwner {
        address owner;
        address receivingAddress;
        bool permanent;
        address[] supportedPayment;
    }
    mapping(bytes32=>TldOwner) public tldToOwner;
    mapping(address=>bytes32) public ownerToTld;

    // A map of conditions that correspond to prices.
    mapping(bytes32=>mapping(bytes32=>uint)) public prices;


    event SetPermanentOwnership(bytes32 indexed tld, bool indexed enable);
    event SetSupportedPayment(bytes32 indexed tld, address[] tokens);

    event UpdateWhitelist(address indexed member, bool indexed enabled);
    event SetReceivingAddress(bytes32 indexed tld, address indexed receivingAddress);
    event SetTld(bytes32 indexed tld, address indexed receivingAddress, bool indexed permanent, bytes32[] condition, uint[] price, address[] payment);

    modifier onlyController {
        require(registryController == msg.sender);
        _;
    }

    constructor(address _registryController) public {
        registryController = _registryController;
        whitelistEnabled = true;
    }

    function updateWhitelist(address member, bool enabled) onlyController public {
        whitelist[member] = enabled;
        emit UpdateWhitelist(member, enabled);
    }

    function setWhitelistEnabled(bool enabled) onlyController public {
        whitelistEnabled = enabled;
    }

    function setTld(string memory tld, address receiveWallet, bytes32[] memory condition, uint[] memory price, address[] memory payment, bool permanent) public {
        require(tld.strlen() == 3);
        if(whitelistEnabled && !whitelist[msg.sender]) {
            revert('Not authorized');
        }
        bytes32 tldHash = keccak256(bytes(tld));
        if(tldToOwner[tldHash].owner != address(0)) {
            require(tldToOwner[tldHash].owner == msg.sender, 'Not tld owner');
        }
        tldToOwner[tldHash] = TldOwner({owner : msg.sender, receivingAddress : receiveWallet, permanent : permanent, supportedPayment: payment});
        ownerToTld[msg.sender] = tldHash;
        require(condition.length == price.length);
        for(uint i = 0; i < condition.length; i++) {
            prices[tldHash][condition[i]] = price[i];
        }
        emit SetTld(StringToBytes32.stringToBytes32(tld), receiveWallet, permanent, condition, price, payment);
    }

    function setReceiveAddress(address receiveWallet) public {
        require(ownerToTld[msg.sender] != bytes32(0));
        tldToOwner[ownerToTld[msg.sender]].receivingAddress = receiveWallet;
        emit SetReceivingAddress(ownerToTld[msg.sender], receiveWallet);
    }

    function getPrice(bytes32 tld, bytes32 condition) external view returns(uint) {
        return prices[tld][condition];
    }

    function permanentOwnershipOfSubnode(bytes32 tld) external view returns(bool) {
        return tldToOwner[tld].permanent;
    }

    function getSupportedPayment(bytes32 tld) public view returns (address[] memory){
        return tldToOwner[tld].supportedPayment;
    }

    function receivingAddress(bytes32 tld) external view returns(address) {
        return tldToOwner[tld].receivingAddress;
    }

    function getTldToOwner(bytes32 tld) external view returns(TldOwner memory) {
        return tldToOwner[tld];
    }
}