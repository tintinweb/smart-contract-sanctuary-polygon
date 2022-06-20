// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "./Base64.sol";
import "./Strings.sol";

contract Chess5 {

    // Contract name
    string private _name;

    // Contract symbol
    string private _symbol;

    // player counter
    uint256 nomPlayers = 0;

    // Validator address (set to owner, a naive implemenation)
    address validator;
    
    struct Stats {
        uint128 wins;
        uint128 losses;
    }

    mapping(address => string) private players;
    mapping(uint256 => address) private ownerships;

    mapping(address => Stats) public stats;
    
    // eip-721
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        validator = msg.sender;
    }

    function register (string memory transactionId) external payable {
        if(msg.value < 0.002 ether || bytes(players[msg.sender]).length > 0) {
            revert();
        } else {
            // gasaster
            players[msg.sender] = transactionId;
            nomPlayers++;
            ownerships[nomPlayers] = msg.sender;
            emit Transfer(address(0), msg.sender, nomPlayers);
        }
    }

    function pushMatchStats( address[] calldata winners, address[] calldata losers) external {
        if(msg.sender != validator || winners.length != losers.length)
            revert();
        
        uint256 index;

        for (index = 0; index < winners.length;) {
                
            if(bytes(players[winners[index]]).length > 0)
                stats[winners[index]].wins++;

            if(bytes(players[losers[index]]).length > 0)
                stats[losers[index]].losses++;
                
            unchecked {
                ++index;
            }
        }

    }


    function balanceOf(address _owner) external view returns (uint256) {
        return bytes(players[_owner]).length > 0 ? 1 : 0;
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return ownerships[_tokenId];
    }

    function supportsInterface(bytes4 interfaceId) public pure  returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        Stats memory tokenStats = stats[ownerships[_tokenId]];
        string memory imageURI = svgToImageURI(tokenStats);

        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            "Chess5 Player #",
                            Strings.toString(_tokenId),
                            '", "description":"A dynamic none-transferable NFT for Chess5 demo score", "attributes":[{"trait_type": "Wins", "value": "',Strings.toString(tokenStats.wins),'"},{"trait_type": "Losses", "value": "',Strings.toString(tokenStats.losses),'"}], "image":"',imageURI,'"}'
                        )
                    )
                )
            );
    }
    

    function svgToImageURI(Stats memory tokenStats) public pure returns (string memory) {

        bytes memory svg = abi.encodePacked(
            '<svg width="350" height="350" viewBox="0 0 350 350" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="350" height="350" fill="white"/><path d="M174.932 0.136719H131.182V43.8867H174.932V0.136719ZM0 43.8662V87.6162H43.75V43.8662H0ZM87.5 0.136719H43.75V43.8867H87.5V0.136719ZM131.25 175.068V218.818H175V175.068H131.25ZM0 131.332V175.082H43.75V131.332H0ZM262.397 0.136719H218.647V43.8867H262.397V0.136719ZM349.897 0.136719H306.147V43.8867H349.897V0.136719ZM87.5 175.068H43.75V218.818H87.5V175.068ZM349.863 306.25V262.5H306.113V306.25H349.863ZM349.863 218.75V175H306.113V218.75H349.863ZM262.397 350H306.147V306.25H262.397V350ZM349.897 131.332V87.582H306.147V131.332H349.897ZM87.5 350H131.25V306.25H87.5V350ZM0 350H43.75V306.25H0V350ZM174.932 350H218.682V306.25H174.932V350ZM0 218.798V262.548H43.75V218.798H0ZM218.668 87.6025V43.8525H174.918V87.6025H218.668ZM174.918 175.103H218.668V131.353H174.918V175.103ZM131.168 262.603V306.353H174.918V262.603H131.168ZM218.668 218.853H262.418V175.103H218.668V218.853ZM218.668 131.387H262.418V87.6367H218.668V131.387ZM218.668 262.589V306.339H262.418V262.589H218.668ZM43.75 262.534V306.284H87.5V262.534H43.75ZM131.25 87.6025V43.8525H87.5V87.6025H131.25ZM262.445 262.534H306.195V218.784H262.445V262.534ZM174.945 131.332V87.582H131.195V131.332H174.945ZM262.445 43.8662V87.6162H306.195V43.8662H262.445ZM174.945 218.798V262.548H218.695V218.798H174.945ZM131.195 131.332H87.5V175.082H131.25L131.195 131.332ZM262.391 175.082H306.141V131.332H262.391V175.082ZM87.5 87.6025H43.75V131.353H87.5V87.6025ZM87.5 218.798V262.548H131.25V218.798H87.5Z" fill="black"/><g filter="url(#filter0_d_5_18)"><rect x="44" y="206" width="262" height="100" rx="8" fill="white"/><rect x="45" y="207" width="260" height="98" rx="7" stroke="black" stroke-width="2"/></g><text x="70" y="240" fill="black" font-size="large">WINS</text><text x="210" y="240" fill="black" font-size="large">LOSSES</text><text x="70" y="270" fill="black" font-size="large">', 
            Strings.toString(tokenStats.wins), 
            '</text><text x="210" y="270" fill="black" font-size="large">',
            Strings.toString(tokenStats.losses),
            '</text><g clip-path="url(#clip0_5_18)"><path d="M162.991 57.5H164.733L163.256 56.5761C156.964 52.6414 152.75 45.7096 152.75 37.75C152.75 31.8489 155.094 26.1896 159.267 22.0169C163.44 17.8442 169.099 15.5 175 15.5C180.901 15.5 186.56 17.8442 190.733 22.0169C194.906 26.1896 197.25 31.8489 197.25 37.75C197.25 45.7096 193.036 52.6414 186.744 56.5761L185.267 57.5H187.009H192.5C193.296 57.5 194.059 57.8161 194.621 58.3787C195.184 58.9413 195.5 59.7043 195.5 60.5V67.5C195.5 68.2957 195.184 69.0587 194.621 69.6213C194.059 70.1839 193.296 70.5 192.5 70.5H189H188.5V71V72.2009C188.5 81.5457 189.343 90.6882 193.414 98.5H156.586C160.651 90.6885 161.5 81.5461 161.5 72.2009V71V70.5H161H157.5C156.704 70.5 155.941 70.1839 155.379 69.6213C154.816 69.0587 154.5 68.2957 154.5 67.5V60.5C154.5 59.7043 154.816 58.9413 155.379 58.3787C155.941 57.8161 156.704 57.5 157.5 57.5H162.991ZM141.379 107.379C141.941 106.816 142.704 106.5 143.5 106.5H206.5C207.296 106.5 208.059 106.816 208.621 107.379C209.184 107.941 209.5 108.704 209.5 109.5V116.5C209.5 117.296 209.184 118.059 208.621 118.621C208.059 119.184 207.296 119.5 206.5 119.5H143.5C142.704 119.5 141.941 119.184 141.379 118.621C140.816 118.059 140.5 117.296 140.5 116.5V109.5C140.5 108.704 140.816 107.941 141.379 107.379Z" fill="white" stroke="black"/><path d="M183.744 37.2319L175 42.574L166.25 37.2319L175 22.2188L183.744 37.2319ZM175 44.2895L166.25 38.9474L175 51.6924L183.75 38.9474L175 44.2895V44.2895Z" fill="black"/></g><text x="140" y="145" fill="red" font-size="large" font-weight="bold">Chess5</text><defs><filter id="filter0_d_5_18" x="40" y="206" width="270" height="108" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dy="4"/><feGaussianBlur stdDeviation="2"/><feComposite in2="hardAlpha" operator="out"/><feColorMatrix type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0"/><feBlend mode="normal" in2="BackgroundImageFix" result="effect1_dropShadow_5_18"/><feBlend mode="normal" in="SourceGraphic" in2="effect1_dropShadow_5_18" result="shape"/></filter><clipPath id="clip0_5_18"><rect width="70" height="112" fill="white" transform="translate(140 8)"/></clipPath></defs></svg>'
        );

        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(svg);

        return string(abi.encodePacked(baseURL,svgBase64Encoded));
    }

}