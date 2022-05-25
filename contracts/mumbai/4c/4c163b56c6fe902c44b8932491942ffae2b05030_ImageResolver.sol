/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// import "@openzeppelin/contracts/access/Ownable.sol";

contract ImageStore {
    //  uint8[][] public images;
    mapping(uint256 => bytes) public images;

    function storeImage(uint256 _hash, bytes calldata _data) external {
        images[_hash] = _data;
    }

    function getImage(uint256 _hash) external view {}
}

contract ImageResolver {
    ImageStore[] public imageStores;

    bytes private constant base64stdchars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes private constant base64urlchars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

    function encode(bytes memory _bs) internal pure returns (string memory) {
        uint256 rem = _bs.length % 3;

        uint256 res_length = ((_bs.length + 2) / 3) * 4 - ((3 - rem) % 3);
        bytes memory res = new bytes(res_length);

        uint256 i = 0;
        uint256 j = 0;

        for (; i + 3 <= _bs.length; i += 3) {
            (res[j], res[j + 1], res[j + 2], res[j + 3]) = encode3(
                uint8(_bs[i]),
                uint8(_bs[i + 1]),
                uint8(_bs[i + 2])
            );

            j += 4;
        }

        if (rem != 0) {
            uint8 la0 = uint8(_bs[_bs.length - rem]);
            uint8 la1 = 0;

            if (rem == 2) {
                la1 = uint8(_bs[_bs.length - 1]);
            }

            (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3) = encode3(la0, la1, 0);
            res[j] = b0;
            res[j + 1] = b1;
            if (rem == 2) {
                res[j + 2] = b2;
            }
        }

        return string(res);
    }

    function encode3(
        uint256 a0,
        uint256 a1,
        uint256 a2
    )
        private
        pure
        returns (
            bytes1 b0,
            bytes1 b1,
            bytes1 b2,
            bytes1 b3
        )
    {
        uint256 n = (a0 << 16) | (a1 << 8) | a2;

        uint256 c0 = (n >> 18) & 63;
        uint256 c1 = (n >> 12) & 63;
        uint256 c2 = (n >> 6) & 63;
        uint256 c3 = (n) & 63;

        b0 = base64urlchars[c0];
        b1 = base64urlchars[c1];
        b2 = base64urlchars[c2];
        b3 = base64urlchars[c3];
    }

    function addStore(address _store) external {
        imageStores.push(ImageStore(_store));
    }

    function getImageInBase64URL(uint32 _storeId, uint256 _hash)
        external
        view
        returns (string memory strRes)
    {
        bytes memory image = imageStores[_storeId].images(_hash);
        strRes = encode(image);
    }
}