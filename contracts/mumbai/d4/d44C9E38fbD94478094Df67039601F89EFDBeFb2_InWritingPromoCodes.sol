// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface InWriting {
    function mint_NFT(string memory str) external payable returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function get_minting_cost() external view returns (uint256);
}

contract InWritingPromoCodes is Ownable {
    address InWriting_address = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    InWriting write = InWriting(InWriting_address);

    mapping(bytes32 => bool) promoCodeUsed; // (hash of user address + promo code -> bool) to keep track of who has used which promo code
    mapping(string => uint256) promoCodes; // (promo code -> remaining uses) to set a cap so the contract doesn't get taken advantage of
    mapping(string => uint8) promoDiscount; // (promo code -> percent discount) [percent * 100; ex: 60% --> promoDiscount = 60]

    mapping(string => bool) affiliateCodeUsed; // (affiliate code -> bool) to keep track of codes so nobody's code get overwritten
    mapping(string => address) affiliateAddress; // (affiliate code -> affiliate address) to keep track of who to pay out for a given affiliate address
    mapping(string => uint8) affiliateDiscount; // (affiliate code -> percent discount) [percent * 100; ex: 60% --> affiliateDiscount = 60]
    mapping(string => uint8) affiliateCommission; // (affiliate code -> percent commission) [percent * 100; ex: 60% --> affiliateCommission = 60]

    constructor() {}

    receive() external payable {}

    function withdraw(uint256 amt) public onlyOwner {
        require(amt <= address(this).balance);
        payable(owner()).transfer(amt);
    }

    function add_promo(
        string memory promo,
        uint256 num,
        uint8 percent
    ) public onlyOwner {
        promoCodes[promo] = num;
        promoDiscount[promo] = percent;
    }

    function add_affiliate(
        string memory promo,
        address addr,
        uint8 percent,
        uint8 commission
    ) public onlyOwner {
        require(!affiliateCodeUsed[promo], "affiliate code already in use");
        affiliateCodeUsed[promo] = true;
        affiliateAddress[promo] = addr;
        affiliateDiscount[promo] = percent;
        affiliateCommission[promo] = commission;
    }

    function remove_affiliate(string memory promo) public onlyOwner {
        affiliateCodeUsed[promo] = false;
        delete affiliateAddress[promo];
        delete affiliateDiscount[promo];
        delete affiliateCommission[promo];
    }

    function get_promo_remaining_uses(string memory promo)
        public
        view
        returns (uint256)
    {
        return promoCodes[promo];
    }

    function get_promo_discount(string memory promo)
        public
        view
        returns (uint8)
    {
        return promoDiscount[promo];
    }

    function get_affiliate_used(string memory promo)
        public
        view
        returns (bool)
    {
        return affiliateCodeUsed[promo];
    }

    function get_affiliate_address(string memory promo)
        public
        view
        returns (address)
    {
        return affiliateAddress[promo];
    }

    function get_affiliate_discount(string memory promo)
        public
        view
        returns (uint8)
    {
        return affiliateDiscount[promo];
    }

    function get_affiliate_commission(string memory promo)
        public
        view
        returns (uint8)
    {
        return affiliateCommission[promo];
    }

    function get_price_with_promo(string memory promo)
        public
        view
        returns (uint256)
    {
        return (write.get_minting_cost() * (100 - promoDiscount[promo])) / 100;
    }

    function get_price_with_affiliate(string memory promo)
        public
        view
        returns (uint256)
    {
        return
            (write.get_minting_cost() * (100 - affiliateDiscount[promo])) / 100;
    }

    function mint_promo_NFT(string memory str, string memory promo)
        public
        payable
        returns (uint256)
    {
        require(
            promoCodeUsed[keccak256(abi.encodePacked(msg.sender, promo))],
            "this promotional code has been used for this address already"
        );
        require(promoCodes[promo] > 0, "this promotional code has expired");
        uint256 cost = (write.get_minting_cost() *
            (100 - promoDiscount[promo])) / 100;
        require(
            msg.value >= cost,
            string(
                abi.encodePacked(
                    "payment not sufficient, this promotional code is only ",
                    Strings.toString(promoDiscount[promo]),
                    "%"
                )
            )
        );

        promoCodes[promo] -= 1;

        uint256 tokenId = write.mint_NFT{value: write.get_minting_cost()}(str);
        write.transferFrom(address(this), msg.sender, tokenId);

        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        return tokenId;
    }

    function mint_and_send_affiliate_NFT(
        string memory str,
        string memory promo,
        address addr
    ) public payable returns (uint256) {
        require(affiliateCodeUsed[promo], "this affiliate code does not exist");
        uint256 cost = ((write.get_minting_cost() *
            (100 - affiliateDiscount[promo])) / 100);
        require(
            msg.value >= cost,
            string(
                abi.encodePacked(
                    "payment not sufficient, this affiliate code is only ",
                    Strings.toString(affiliateDiscount[promo]),
                    "%"
                )
            )
        );

        uint256 tokenId = write.mint_NFT{value: write.get_minting_cost()}(str);
        write.transferFrom(address(this), addr, tokenId);

        payable(affiliateAddress[promo]).transfer(
            (cost * affiliateCommission[promo]) / 100
        );
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        return tokenId;
    }

    function mint_affiliate_NFT(string memory str, string memory promo)
        public
        payable
        returns (uint256)
    {
        return mint_and_send_affiliate_NFT(str, promo, msg.sender);
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