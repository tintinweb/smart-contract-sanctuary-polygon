//SPDX-License-Identifier: Regret

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";
import "./IDoomsdaySurvivors.sol";
import "./IDoomsday.sol";

contract DoomsdaySurvivorsMetadata is Ownable{
    IDoomsday doomsday;
    IDoomsdaySurvivors survivors;
    constructor(address _doomsday, address _survivors){
        doomsday  = IDoomsday(_doomsday);
        survivors = IDoomsdaySurvivors(_survivors);
    }

    string private __imageBase = "https://gateway.pinata.cloud/ipfs/QmVLJZgubEhGRXdE8tTBGKDg9hnhEmPtfkbh24X9Bmtv4E/";
    string private __imageSuffix = ".png";

    string tokenDescription = "Doomsday NFT Survivors are a series of 1000 unique characters that exist in the Doomsday NFT universe. Survivors can seek shelter in any Doomsday NFT Bunker, and any Survivors in the final Bunker that remains the end of the Apocalypse will split a prize pool of MATIC from Survivor mint fees. Survivor character art was created by artist Ghost Agent.";

    function tokenURI(uint256 _tokenId) public view returns (string memory){
        //Note: changed visibility to public
        survivors.ownerOf(_tokenId);


        string memory location;
        string memory status;
        if(survivors.tokenToBunker(_tokenId) != 0){
            location = "Bunker";
            try doomsday.ownerOf(survivors.tokenToBunker(_tokenId)){
                status = "Detected";
            }catch{
                status = "Not Detected";
            }
        }else{
            location = "Outside";
            if(doomsday.stage() == IDoomsday.Stage.PreApocalypse){
                status = "Detected";
            }else{
                status = "Not Detected";
            }

        }
        string memory attributes = string(abi.encodePacked('{"trait_type":"Location","value":"',location,'"},{"trait_type":"Vital Signs","value":"',status,'"}'));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Survivor #', toString(_tokenId),'", "description": "', tokenDescription,'", "attributes":[',attributes,'], "image": "',__imageBase,toString(survivors.tokenToSurvivor(_tokenId)),__imageSuffix,'" }'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }





    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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

    function setImageUriComponents(string calldata _newBase, string calldata _newSuffix) public onlyOwner{
        __imageBase   = _newBase;
        __imageSuffix = _newSuffix;
    }

    function setDescription(string memory _description) public onlyOwner{
        tokenDescription = _description;
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

pragma solidity ^0.8.0;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: Shame

pragma solidity ^0.8.4;

interface IDoomsdaySurvivors {
    function balanceOf(address _owner) external view returns(uint);
    function ownerOf(uint _tokenId) external view returns(address);
    function saleActive() external view returns(bool);
    function totalSupply() external view returns(uint);

    function tokenToSurvivor(uint _tokenId) external view returns(uint);
    function tokenToBunker(uint _tokenId) external view returns(uint);
    function withdrawn(uint _tokenId) external view returns(bool);

}

// SPDX-License-Identifier: Fear

pragma solidity ^0.8.4;

interface IDoomsday {
    enum Stage {Initial,PreApocalypse,Apocalypse,PostApocalypse}
    function stage() external view returns(Stage);
    function totalSupply() external view returns (uint256);
    function isVulnerable(uint _tokenId) external view returns(bool);

    function ownerOf(uint256 _tokenId) external view returns(address);

    function confirmHit(uint _tokenId) external;
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