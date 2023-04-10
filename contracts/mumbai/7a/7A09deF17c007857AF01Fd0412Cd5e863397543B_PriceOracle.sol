/**
 *Submitted for verification at polygonscan.com on 2023-04-09
*/

pragma solidity ^0.8.0;

//interface PriceOracle {
//    /**
//     * @dev Returns the price to register.
//     * @param condition keccak256 multiple conditions, like payment token address, duration, length, etc.
//     * @return The price of this registration.
//     */
//    function prices(bytes32 condition) external view returns(uint);
//
//    /**
//     * @dev Returns the payment token addresses according to a specific tld.
//     * @param tld keccak256 tld.
//     * @return The payment token addresses.
//     */
//    function supportedPayment(bytes32 tld) external view returns(address[] memory);
//
//    /**
//     * @dev Returns the permanent ownership status of subnode belonged to a tld.
//     * @param tld keccak256 tld.
//     * @return The permanent ownership status of subnode belonged to a tld
//     */
//    function permanentOwnershipOfSubnode(bytes32 tld) external view returns(bool);
//}

contract PriceOracle {
    address public registryController;

    // A map of tld hashes that support payment tokens.
    mapping(bytes32=>address[]) public supportedPayment;

    // A map of tld hashes that enable permanent ownership of subnode.
    mapping(bytes32=>bool) public permanentOwnershipOfSubnode;

    // A map of conditions that correspond to prices.
    mapping(bytes32=>uint) public prices;

    modifier onlyController {
        require(registryController == msg.sender);
        _;
    }

    constructor(address _registryController) public {
        registryController = _registryController;
    }
    
    function getSupportedPayment(bytes32 condition) public view returns (address[] memory){
        return supportedPayment[condition];
    }

    function setPrice(bytes32 condition, uint price) public onlyController {
        prices[condition] = price;
    }

    function setPermanentOwnership(bytes32 tld) public onlyController {
        permanentOwnershipOfSubnode[tld] = true;
    }

    function setSupportedPayment(bytes32 tld, address[] calldata tokens) public onlyController {
        supportedPayment[tld] = tokens;
    }

    function addSupportedPayment(bytes32 tld, address token) public onlyController {
        supportedPayment[tld].push(token);
    }
 }