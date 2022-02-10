// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";

// kkkkkkkkkkkkkkkkkkdlllldkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
// kkkkkkkkkkkkkxlccc,';:;;okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
// kkkkkkkkkkkkkc';:::lc;:cdkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
// kkkkkkkkkkkkl',::cc:;:lloddxxdddxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
// kkkkkkkkkkkd;';:;clodxkxOKXXXXKOkkxxdxkkkkkkkkkkkkkkkkkkkkkkkkkkkk
// kkkkkkkkkkkxlloxclkxOXWMMMMMMMMMMMWX0kxdxkkkkkkkkkxxkkkkkkkkkkkkkk
// kkkkkkkkkkkkkkkkc:kNMMMMMMMMMMMWXK000KOl;:loxkkkko;;clldkkkkkkkkkk
// kkkkkkkkkkkkkkkd;:dk0NMMMMMMMW0l:;;;;:;,;:;;::clddl;',;clloxkkkkkk
// kkkkkkkkkkkkkkd:,,;,;cdKNWNKOo;;::cccccc::::c:;;;:;;ll;:c::dkkkkkk
// kkkkkkkkkkkkkd:;::::c:;;clc:;;:c::::::::::::::::cc:::l;:xxxkkkkkkk
// kkkkkkkkkkkxl;;::::::::cc:cc::::::::::::::::;;,,,,,,,,.,dkkkkkkkkk
// kkkkkkkkkkd:;::::c::::::::ccc::::::cc::;,,''''''''''''..ckkkkkkkkk
// kkkkkkkkdc;;::;,,,'''''',,,,,,;;;;,,,''''''''.....',,,,.:xkkkkkkkk
// kkkkkkko;;:;,'''',,,''''''..'''''''''''';coxd'.'''..',''lkkkkkkkkk
// kkkkkkl,::,'',,,'.,cloddddolcc:;;:::cldk0XNN0:.,,,..,''/lkkkkkkkkkk
// kkkkkd;;;'',,,....dXNNNNNNNNNXKKKKKXXNNNNXXNKl.,,,'',:!dkkkkkkkkkkk
// kkkkkl,;'','...'.'kNXXNNNNNNNXXXNNXXXNNNNNNNNk;.',;cdkkkkkkkkkkkkk
// kkkkkl,..,,..,,,':0NNX0OkkKNNNXNNNNNNXXXNXOkkOk::dkkkkkkkkkkkkkkkk
// kkkkkx;..,'.',,,'oXXNOokkoONNNXNKOxd0XNXNKdxOdkk:cxkkkkkkkkkkkkkkk
// kkkkkkd;.',',,,.,ONNNKkkkOXNNNNXkoxxkKNNNNKkOdc;..:oodkkkkkkkkkkkk
// kkkkkkkxl,''',,..,cdOKNNNXXNXXNNNNXNNXNNXNXOo;''. .'',:dkkkkkkkkkk
// kkkkkkkkkxoc;,..,,...,cdkOKXXNNNXXNNNNXNXx:.......','..ckkkkkkkkkk
// kkkkkkkkkkkdc;,,,''.......',;cld0KXNNXXNKl. .....',,,.,dkkkkkkkkkk
// kkkkkkkkkkx:,''',,,,,,''........',;lkKNXNXc.',,,,,'..'lkkkkkkkkkkk
// kkkkkkkkkkd::,',,,,,,,,,,,,,,,,,,,'.':dKXx.....''...'lxkkkkkkkkkkk
// kkkkkkkkkkklco,.,,'','..',,,,,,,,,,,,,';c'.'::::;...ckkkkkkkkkkkkk
// kkkkkkkkkkkxlcl:'',''''..',,,,,,,,,,,,,'...';,,'..'lxkkkkkkkkkkkkk
// kkkkkkkkkkkkkdlll:'''''''.',,,,,,,,,,,ll''''....,cokkkkkkkkkkkkkkk
// kkkkkkkkkkkkkkkdcc;..''......'''''''';do::,....:dkkkkkkkkkkkkkkkkk
// kkkkkkkkkkkkkkkkxo:,;cl;. ..,clllllooddxkkxdodxkkkkkkkkkkkkkkkkkkk
// kkkkkkkkkkkkkkkkkkkkkkkxdoodxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
// kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
// kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk

contract MoodyMushroomsItemShop is ERC1155, Ownable {
    using Strings for uint256;
    
    string private baseURI;

    mapping(uint256 => bool) public validItems;

    string public constant C____ = "     ,---.    ";
    string public constant _O___ = "    ' ,~, `   ";
    string public constant __I__ = "   ( ( ..) )  ";
    string public constant ___N_ = "    . ( ) .   ";
    string public constant ____S = "     `---'    ";
 
    event SetBaseURI(string indexed _baseURI);

    //######      item codes       ######
    //###### 0-199   - Accessories ######
    //###### 200-399 - Backgrounds ######
    //###### 400-599 - Spots       ######
    //###### 600-799 - Costumes    ######
    //###### 800-999 - Moods       ######

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI;
        validItems[0] = true;
        validItems[1] = true;
        validItems[69] = true;
        validItems[200] = true;
        validItems[400] = true;
        validItems[420] = true;
        validItems[600] = true;
        validItems[800] = true;
        validItems[999] = true;
        emit SetBaseURI(baseURI);
    }


    function mintBatch(uint256[] memory ids, uint256[] memory amounts) external onlyOwner
    {
        _mintBatch(owner(), ids, amounts, "");
    }


    function burnItem(uint256 typeId, address burnTokenAddress) external
    {
        _burn(burnTokenAddress, typeId, 1);
    }

    // DM ImEmmy in discord, tell him you're a zombie coming to snack on his brain
    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(baseURI);
    }

    function uri(uint256 typeId) public view override returns (string memory)
    {
        require(
            validItems[typeId],
            "URI requested for invalid serum type"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString()))
                : baseURI;
    }
}