// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../Interfaces.sol";
//import "hardhat/console.sol"; 

/*

███████╗██╗░░░░░██╗░░░██╗███████╗███╗░░██╗  ░██╗░░░░░░░██╗░█████╗░██╗░░░░░██╗░░░░░███████╗████████╗
██╔════╝██║░░░░░██║░░░██║██╔════╝████╗░██║  ░██║░░██╗░░██║██╔══██╗██║░░░░░██║░░░░░██╔════╝╚══██╔══╝
█████╗░░██║░░░░░╚██╗░██╔╝█████╗░░██╔██╗██║  ░╚██╗████╗██╔╝███████║██║░░░░░██║░░░░░█████╗░░░░░██║░░░
██╔══╝░░██║░░░░░░╚████╔╝░██╔══╝░░██║╚████║  ░░████╔═████║░██╔══██║██║░░░░░██║░░░░░██╔══╝░░░░░██║░░░
███████╗███████╗░░╚██╔╝░░███████╗██║░╚███║  ░░╚██╔╝░╚██╔╝░██║░░██║███████╗███████╗███████╗░░░██║░░░
╚══════╝╚══════╝░░░╚═╝░░░╚══════╝╚═╝░░╚══╝  ░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚══════╝╚══════╝╚══════╝░░░╚═╝░░░

The Ethernal Elves Wallet
*/


contract ElvenWallet {

    using ECDSA for bytes32;

    IERC20Lite public ren;
    IERC20Lite public moon;
    IERC20Lite public slp;
    IElves public elves;
    ///////////////////////////////////////////////////////////////////////////////////////////

    bool public initialized;
    bool public isActive;
    address public admin;
    uint256 public slpSwapRate;    
    mapping(address => bool)   public auth;  
    uint256 moonForLPs;
    uint256 public moonForLPsLeft;
    
    
   
    ///Add more assets here

   function initialize() public {
    
       require(!initialized, "Already initialized");
       admin                = msg.sender;   
       initialized          = true;
       slpSwapRate          = 10;
    }

    function setAddresses(address _elves, address _ren, address _moon, address _slp)  public {
       onlyOwner();
       elves                = IElves(_elves);
       ren                  = IERC20Lite(_ren);
       moon                 = IERC20Lite(_moon);
       slp                  = IERC20Lite(_slp);
       isActive             = true;
    }

    function setSlpSwapRate(uint256 _slp)  public {
       onlyOwner();
       slpSwapRate                = _slp;
    }
    function setMoonForLP(uint256 _moonForLp)  public {
       onlyOwner();
       moonForLPs                = _moonForLp;
       moonForLPsLeft            = _moonForLp;     
    }

    function getSlpSwapRate() public view returns (uint256 swapRate) {            

            if (moonForLPsLeft <     50000 ether) return  ( 20 );
            if (moonForLPsLeft <    100000 ether) return  ( 22 );
            if (moonForLPsLeft <    150000 ether) return  ( 24 );
            if (moonForLPsLeft <    200000 ether) return  ( 26 );
            if (moonForLPsLeft <    500000 ether) return  ( 28 );
            if (moonForLPsLeft <    800000 ether) return  ( 32 );
            if (moonForLPsLeft <   1100000 ether) return  ( 36 );
            if (moonForLPsLeft <= moonForLPs) return  ( 50 );

    }

    function setAuth(address[] calldata adds_, bool status) public {
        onlyOwner();
                
        for (uint256 index = 0; index < adds_.length; index++) {
               auth[adds_[index]] = status;
        }
    } 

    function flipActiveStatus() external {
        onlyOwner();
        isActive = !isActive;
    } 


    function deposit(address _owner, uint256 _tokenAmounts, uint256 tokenIndex) external {
        
            onlyOperator();
            checkWalletStatus();
            
            if(tokenIndex == 0){
                        elves.setAccountBalance(_owner, _tokenAmounts, false, 0);  
                        ren.burn(_owner, _tokenAmounts);

            }else if(tokenIndex == 1){
                        elves.setAccountBalance(_owner, _tokenAmounts, false, 1);      
                        moon.transferFrom(_owner, address(this), _tokenAmounts);
            }
            
    } 

        function withdraw(address _owner, uint256 _tokenAmounts, uint256 tokenIndex) external {
        
            onlyOperator();
            checkWalletStatus();
            
             if(tokenIndex == 0){
                        
                        elves.setAccountBalance(_owner, _tokenAmounts, true, 0);      
                        ren.mint(_owner, _tokenAmounts);
                      
             }else if(tokenIndex == 1){
                
                        elves.setAccountBalance(_owner, _tokenAmounts, true, 1);  
                        moon.transfer(_owner, _tokenAmounts);                           
                      
            }
            
    }

    function exchangeSLPForMoon(address _owner, uint256 _amount) external
    {   
        onlyOperator();
        checkWalletStatus();
        
        require(_amount > 0, "Amount is 0");
        require(_amount % 10**18 == 0, "Must be an integer amount of SLP");
        
        uint256 _swapRate = getSlpSwapRate();
        uint256 _moonAmount = _amount * _swapRate;
        
        require(moonForLPsLeft - _moonAmount > 0, "Not enough MOON");
        require(moonForLPsLeft > 0, "No MOON left");
         
        moonForLPsLeft = moonForLPsLeft - _moonAmount;        

        slp.transferFrom(_owner, address(this), _amount);           
        moon.transfer(_owner, _moonAmount);
        
    }

    function withdrawSLP(uint256 _amount) external
    {   
        onlyOwner();
        slp.transfer(msg.sender, _amount); 
        
    }
    
    function depositSLP(uint256 _amount) external
    {   
        onlyOwner();
        slp.transferFrom(msg.sender, address(this), _amount); 
        
    }

            ////////////////MODIFIERS//////////////////////////////////////////

            function checkBalance(uint256 balance, uint256 amount) internal view {    
            require(balance - amount >= 0, "notEnoughBalance");           
            }
            function checkWalletStatus() internal view {
            require(isActive, "walletInactive");       
            }
            function onlyOperator() internal view {    
            require(msg.sender == admin || auth[msg.sender] == true);
            }
            function isPlayer() internal {    
            uint256 size = 0;
            address acc = msg.sender;
            assembly { size := extcodesize(acc)}
            require((msg.sender == tx.origin && size == 0));
            }
            function onlyOwner() internal view {    
            require(admin == msg.sender, "notOwner");
            }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface IERC20Lite {
    
    function transfer(address to, uint256 value) external returns (bool);
    function burn(address from, uint256 value) external;
    function mint(address to, uint256 value) external; 
    function approve(address spender, uint256 value) external returns (bool); 
    function balanceOf(address account) external returns (uint256); 
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

interface IElfMetaDataHandler {    
function getTokenURI(uint16 id_, uint256 sentinel) external view returns (string memory);
}

interface ICampaigns {
function gameEngine(uint256 _campId, uint256 _sector, uint256 _level, uint256 _attackPoints, uint256 _healthPoints, uint256 _inventory, bool _useItem) external 
returns(uint256 level, uint256 rewards, uint256 timestamp, uint256 inventory);
}

/*
interface ITunnel {
    function sendMessage(bytes calldata message_) external;
}

interface ITerminus {
    function pullCallback(address owner, uint256[] calldata ids) external;
    
}
*/

interface IElders {


}

interface IArtifacts {

    
}

interface IElves {    
    function prismBridge(uint256[] calldata id, uint256[] calldata sentinel, address owner) external;    
    function exitElf(uint256[] calldata ids, address owner) external;
    function setAccountBalance(address _owner, uint256 _amount, bool _subtract, uint256 _index) external;
}

interface IERC721Lite {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

/*
interface IEthernalElves {
function presale(uint256 _reserveAmount, address _whitelister) external payable returns (uint256 id);
}
*/

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