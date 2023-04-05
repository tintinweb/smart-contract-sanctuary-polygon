// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/utils/Base64.sol";

interface IGen3ImageLib1 {
    function generateCharacter(string memory _color1, string memory _color3, string memory _color4, string memory _color5 ) external pure returns(string memory);
}
interface IGen3ImageLib2 {
    function generateCharacter(string memory _result, string memory _color1, string memory _color3, string memory _color4, string memory _color5, string memory _chromosome ) external pure returns(string memory);
}
contract Gen3Image{
    IGen3ImageLib1 public lib1;
    IGen3ImageLib2 public lib2;

    constructor(address _lib1, address _lib2){
        lib1 = IGen3ImageLib1(_lib1);
        lib2 = IGen3ImageLib2(_lib2);
    }

    function getImage(string[4] memory _color, string memory _chromosome, bool _mutated) external view returns(string memory) {
        string memory _result = lib1.generateCharacter(_color[0],_color[1],_color[2],_color[3]);
        _result = lib2.generateCharacter(_result, _color[0],_color[1],_color[2],_color[3],_chromosome);
        return _result;
    }


    /// COLOR

    string[4][4] cWater = [ 
        ["#48314b","#382a52","#4c3040","#39293a"],
        ["#51577b","#467086","#5c477d","#7c649b"],
        ["#638fb1","#4fc5bc","#5f62b5","#01bbdb"],
        ["#dddcc3","#e4cebc","#eaf2e3","#e3d77b"]
    ]; 
    string[4][4] cNormal = [
        ["#1f2f30","#1a3528","#1e2631","#293031"],
        ["#5b7669","#547d54","#487476","#aebfa8"],
        ["#aebfb1","#b2c4a9","#9ec0b6","#5b7375"],
        ["#e4efe9","#e2f2e1","#ecf8f7","#ebe7b5"]
    ]; 
    string[4][4] cGrass = [
        ["#31433d","#2c4830","#2d3b47","#332e51"],
        ["#40644f","#3c6e36","#2d5f6b","#228573"],
        ["#90b66f","#c6c85d","#5ec780","#8dc95e"],
        ["#dbeeca","#f7f8c0","#f7f0e9","#e6edb4"]
    ];
    string[4][4] cRock = [
        ["#3d343b","#3b323f","#3d3436","#1e2742"],
        ["#6b4859","#734073","#794441","#873661"],
        ["#7f8a8f","#7c938f","#70758e","#657278"],
        ["#e3e0d3","#e7d6d0","#edf2e3","#d4a86e"]
    ];
    string[4][4] cGround = [
        ["#373131","#392f34","#373431","#402624"],
        ["#6b5045","#753b49","#6b685a","#854631"],
        ["#9c816a","#a95d61","#9f9e67","#615c4f"],
        ["#d1d7bb","#ded2b4","#d6f0ce","#edb33e"]
    ];
    // Rare bug,fire,poison,fighting,flying
    string[4][4] cBug = [
        ["#4f4355","#474256","#584054","#512574"],
        ["#6d5e94","#555e9d","#8e499e","#a400bd"],
        ["#ed8cdf","#e586f3","#fa7fa7","#ff08a4"],
        ["#e7eddd","#eeeddc","#deefdb","#ffd633"]
    ];
    string[4][4] cFire = [
        ["#4b4658","#454859","#4e4559","#3c3362"],
        ["#c5485a","#cd408f","#c94544","#d63c60"],
        ["#e9b463","#f1775b","#edca5f","#6ac7ce"],
        ["#f7ecc4","#fad6c1","#f9f8e5","#f4d289"]
    ];
    string[4][4] cPoison = [
        ["#473f52","#3e3e53","#503b56","#290f33"],
        ["#724885","#574489","#8f3e8c","#a137ed"],
        ["#9c7fb1","#857cb4","#b171c0","#da43ff"],
        ["#d9debf","#e0d7bd","#ccff9c","#92ed37"]
    ];
    string[4][4] cFighting = [
        ["#483340","#4a2f4c","#49323d","#1e141a"],
        ["#534e6b","#485371","#5a4b79","#2f2136"],
        ["#98627a","#a2589a","#9a4861","#551737"],
        ["#eddce2","#f0d9ec","#fef2f4","#a6336a"]
    ];
    string[4][4] cFlying = [
        ["#3f3b37","#3f3737","#3f3c37","#4a195c"],
        ["#4b5e5d","#3a624a","#3b5b5e","#555c82"],
        ["#bf7753","#c54d57","#c28750","#e76c58"],
        ["#d6d6d6","#deb5aa","#fbefef","#6dddbd"]
    ];
    // Legendary dragon,ice,psychic,ghost,electric
    string[4][4] cDragon = [
        ["#443546","#403546","#463541","#210f1a"],
        ["#a8516a","#b13f79","#aa5842","#342447"],
        ["#87beed","#86d4ee","#8794ed","#a83a6a"],
        ["#e4f4f2","#e4f4ef","#e4f0f4","#00aae8"]
    ];
    string[4][4] cIce = [
        ["#316c83","#317e83","#315c83","#141930"],
        ["#489eba","#47b7bb","#6595ba","#d4f8ff"],
        ["#41e7e2","#40e8be","#9fd6e9","#0ba9b8"],
        ["#ecf2d2","#f2f1d2","#e6f2d2","#1edfe6"]
    ];
    string[4][4] cPsychic = [
        ["#403737","#40373b","#403937","#3118ad"],
        ["#e960b6","#e35eeb","#e9609b","#edd537"],
        ["#2dbed7","#2adaa7","#2d9cd7","#ff14e8"],
        ["#f8d766","#fa9664","#f8f466","#18d8ed"]
    ];
    string[4][4] cGhost = [
        ["#cc5bb7","#995acd","#ea5eb3","#00bbff"],
        ["#6e3fa1","#3f4ea1","#9a2ccc","#ec17ff"],
        ["#3f3546","#353646","#4c3652","#3f264d"],
        ["#cfd0ea","#cfe1ea","#f1f0fa","#6d27ab"]
    ];
    string[4][4] cElectric = [
        ["#4c3848","#5b4353","#4a3a43","#363340"],
        ["#b6722f","#d09942","#a88f3d","#ffd900"],
        ["#f7b82d","#fbdd64","#e2db42","#575f7d"],
        ["#f9eec8","#ffffff","#f2f4cd","#37eded"]
    ];
    string[4][4] cUnknown = [
        ["#2b2c30","#2b2c30","#2b2c30","#2b2c30"],
        ["#323645","#323645","#323645","#323645"],
        ["#5f6585","#5f6585","#5f6585","#5f6585"],
        ["#e7d4ad","#e7d4ad","#e7d4ad","#e7d4ad"]
    ];


    // Common water,normal,grass,rock,ground
    // Rare bug,fire,poison,fighting,flying
    // Legendary dragon,ice,psychic,ghost,electric
    function getColor(string memory _elemental) external view returns(string[4][4] memory color){
        if(keccak256(abi.encode(_elemental)) == keccak256(abi.encode("water"))){
            return water();
        }else if(keccak256(abi.encode(_elemental)) == keccak256(abi.encode("normal"))){
            return normal();
        }else if(keccak256(abi.encode(_elemental)) == keccak256(abi.encode("grass"))){
            return grass();
        }else if(keccak256(abi.encode(_elemental)) == keccak256(abi.encode("rock"))){
            return rock();
        }else if(keccak256(abi.encode(_elemental)) == keccak256(abi.encode("ground"))){
            return ground();
        }else if(keccak256(abi.encode(_elemental)) == keccak256(abi.encode("bug"))){
            return bug();
        }else if(keccak256(abi.encode(_elemental)) == keccak256(abi.encode("fire"))){
            return fire();
        }else if(keccak256(abi.encode(_elemental)) == keccak256(abi.encode("poison"))){
            return poison();
        }else if(keccak256(abi.encode(_elemental)) == keccak256(abi.encode("fighting"))){
            return fighting();
        }else if(keccak256(abi.encode(_elemental)) == keccak256(abi.encode("flying"))){
            return flying();
        }else if(keccak256(abi.encode(_elemental)) == keccak256(abi.encode("dragon"))){
            return dragon();
        }else if(keccak256(abi.encode(_elemental)) == keccak256(abi.encode("ice"))){
            return ice();
        }else if(keccak256(abi.encode(_elemental)) == keccak256(abi.encode("psychic"))){
            return psychic();
        }else if(keccak256(abi.encode(_elemental)) == keccak256(abi.encode("ghost"))){
            return ghost();
        }else if(keccak256(abi.encode(_elemental)) == keccak256(abi.encode("electric"))){
            return electric();
        }else if(keccak256(abi.encode(_elemental)) == keccak256(abi.encode("unknown"))){
            return unknown();
        }else{
            return normal();
        }
    }

    function getMutationColor() external view returns(string[4][4][15] memory){
        string[4][4][15] memory mutationColor;
        mutationColor = [water(),normal(),grass(),rock(),ground(),bug(),fire(),poison(),fighting(),flying(),dragon(),ice(),psychic(),ghost(),electric()];
        return mutationColor;
    }

    function water() public view returns(string[4][4] memory){
        return cWater;
    }
    function normal() public view returns(string[4][4] memory){
        return cNormal;
    }
    function grass() public view returns(string[4][4] memory){
        return cGrass;
    }
    function rock() public view returns(string[4][4] memory){
        return cRock;
    }
    function ground() public view returns(string[4][4] memory){
        return cGround;
    }
    function bug() public view returns(string[4][4] memory){
        return cBug;
    }
    function fire() public view returns(string[4][4] memory){
        return cFire;
    }
    function poison() public view returns(string[4][4] memory){
        return cPoison;
    }
    function fighting() public view returns(string[4][4] memory){
        return cFighting;
    }
    function flying() public view returns(string[4][4] memory){
        return cFlying;
    }
    function dragon() public view returns(string[4][4] memory){
        return cDragon;
    }
    function ice() public view returns(string[4][4] memory){
        return cIce;
    }
    function psychic() public view returns(string[4][4] memory){
        return cPsychic;
    }
    function ghost() public view returns(string[4][4] memory){
        return cGhost;
    }
    function electric() public view returns(string[4][4] memory){
        return cElectric;
    }
    function unknown() public view returns(string[4][4] memory){
        return cUnknown;
    }

}