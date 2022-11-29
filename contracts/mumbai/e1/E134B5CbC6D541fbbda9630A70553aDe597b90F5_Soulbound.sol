pragma solidity >=0.8.0;

import "erc1155soul/contracts/ERC1155Soul.sol";

contract Soulbound is ERC1155Soul {

    /// @param tos are the array of the acconts to receive the SBTs.
    function mint(
        address[] calldata tos
    ) external {
        _mint(tos);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return "https://my-soubound-metadata-uri/{id}";
    }

}

// SPDX-License-Identifier: MIT
// Creator: Ctor Lab (https://ctor.xyz)

pragma solidity >=0.8.0;

import "solmate/src/utils/SSTORE2.sol";


abstract contract ERC1155Soul {
    uint256 private constant ADDRESS_SIZE = 20;

    uint256 private _batchIndex;
    mapping(uint256 => address) private _batchDataStorage;

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    error NotImplemented();
    error BalanceQueryForZeroAddress();
    error InputLengthMistmatch();
    error ExceedBatchSize();


    function uri(uint256 id) public view virtual returns (string memory);

    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    function _batchSize() internal view virtual returns (uint256) {
        return 500;
    }

    function _nextTokenId() internal view virtual returns (uint256) {
        return _startTokenId() + _batchIndex * _batchSize();
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        revert NotImplemented();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        revert NotImplemented();
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        revert NotImplemented();
    }


    function balanceOf(address account, uint256 id) public view virtual returns (uint256) {
        if(account == address(0)) {
            revert BalanceQueryForZeroAddress();
        }

        if(id < _startTokenId()) {
            return 0;
        }

        uint256 batch = (id - _startTokenId()) / _batchSize();
        uint256 start = ((id - _startTokenId()) % _batchSize()) * ADDRESS_SIZE;
        uint256 end = start + ADDRESS_SIZE;

        address dataStorage = _batchDataStorage[batch];

        if(dataStorage == address(0)) {
            return 0;
        }

        if(dataStorage.code.length < end + SSTORE2.DATA_OFFSET) {
            return 0;
        }

        bytes memory data = SSTORE2.read(
            dataStorage
            , start, end
        );

        address owner;
        assembly {
            owner := mload(add(data, ADDRESS_SIZE))
        } 
        if(account == owner) {
            return 1;
        } else {
            return 0;
        }
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        if(accounts.length != ids.length) {
            revert InputLengthMistmatch();
        }

        uint256[] memory batchBalances = new uint256[](accounts.length);
        unchecked {
            for (uint256 i = 0; i < accounts.length; ++i) {
                batchBalances[i] = balanceOf(accounts[i], ids[i]);
            }   
        }
        return batchBalances;
        
    }


    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }


    function _mint(
        address[] memory tos
    ) internal virtual {
        uint256 next = _nextTokenId();
        if(tos.length > _batchSize()) {
            revert ExceedBatchSize();
        }

        bytes memory buffer;
        assembly {
            buffer := tos // cast address[] to bytes
        }

        unchecked {
            require(next + tos.length > next); //no overflow  
            for (uint256 i = 0; i < tos.length; i++) {
                address to = tos[i];

                // remove the zeros between addresses in the array, so we won't wasting gas on storing the zeros.
                bytes32 toBytes32 = bytes32(bytes20(to));
                assembly {  
                    mstore(add(add(buffer, mul(i, ADDRESS_SIZE)),32), toBytes32)
                } 
                    
                emit TransferSingle(msg.sender, address(0), to, next + i, 1);
            }    
        }
        uint256 bufferLength = tos.length * ADDRESS_SIZE;
        assembly {  
            // fill in the length of the buffer size.
            mstore(buffer, bufferLength)
        } 

        _batchDataStorage[_batchIndex] = SSTORE2.write(
            buffer
        );
        _batchIndex++;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        /// @solidity memory-safe-assembly
        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}