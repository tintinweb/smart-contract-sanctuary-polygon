// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
                  ___           ___           ___       ___           ___           ___     
      ___        /\  \         /\  \         /\__\     /\  \         /\  \         /\  \    
     /\  \      /::\  \       /::\  \       /:/  /    /::\  \       /::\  \       /::\  \   
     \:\  \    /:/\:\  \     /:/\:\  \     /:/  /    /:/\:\  \     /:/\:\  \     /:/\ \  \  
     /::\__\  /:/  \:\  \   /:/  \:\  \   /:/  /    /:/  \:\  \   /::\~\:\  \   _\:\~\ \  \ 
  __/:/\/__/ /:/__/ \:\__\ /:/__/ \:\__\ /:/__/    /:/__/ \:\__\ /:/\:\ \:\__\ /\ \:\ \ \__\
 /\/:/  /    \:\  \  \/__/ \:\  \ /:/  / \:\  \    \:\  \ /:/  / \/_|::\/:/  / \:\ \:\ \/__/
 \::/__/      \:\  \        \:\  /:/  /   \:\  \    \:\  /:/  /     |:|::/  /   \:\ \:\__\  
  \:\__\       \:\  \        \:\/:/  /     \:\  \    \:\/:/  /      |:|\/__/     \:\/:/  /  
   \/__/        \:\__\        \::/  /       \:\__\    \::/  /       |:|  |        \::/  /   
                 \/__/         \/__/         \/__/     \/__/         \|__|         \/__/    
*/
import "./Ownable.sol";

import "./Metadata.sol";

contract iColors is Ownable {
    using Strings for uint256;

    event Published(address from, uint256 count, uint256 fee);
    event Minted(
        address from,
        address to,
        string color,
        uint24 amount,
        uint256 fee
    );

    struct Publisher {
        uint24[] colorList;
        string name;
        string description;
        bool exists;
    }

    struct Holder {
        uint24[] colorList;
        uint24[] amounts;
        uint256 globalId;
        bool exists;
    }

    struct Color {
        string attr;
        uint24 amount;
        address publisher;
    }

    mapping(address => Publisher) publishers;
    mapping(address => Holder) holders;
    mapping(uint24 => Color) colors;
    address[] globalTokens;

    uint256 public Rate = 1;
    uint256 public Floor = 0.0001 ether;

    constructor() {}

    function publish(
        string calldata _name,
        string calldata _description,
        uint24[] calldata _colors,
        uint24[] calldata _amounts,
        string[] calldata _attrs
    ) external payable {
        uint256 weight = 0;

        if (publishers[msg.sender].exists) {
            if (bytes(_name).length > 0) {
                // Only change name when not empty
                publishers[msg.sender].name = _name;
                publishers[msg.sender].description = _description;
                weight = bytes(_name).length + bytes(_description).length;
            }
            // search very color to merge them
            uint256 size = publishers[msg.sender].colorList.length;

            for (uint256 i = 0; i < _colors.length; i++) {
                require(
                    colors[_colors[i]].publisher == address(0) ||
                        colors[_colors[i]].publisher == msg.sender,
                    "Color userd"
                );

                uint256 j;
                for (j = 0; j < size; j++) {
                    if (publishers[msg.sender].colorList[j] == _colors[i]) {
                        colors[_colors[i]].amount += _amounts[i];
                        break;
                    }
                }
                if (j == size) {
                    // this is a new color
                    publishers[msg.sender].colorList.push(_colors[i]);
                    colors[_colors[i]] = Color(
                        _attrs[i],
                        _amounts[i],
                        msg.sender
                    );
                }
                weight += bytes(_attrs[i]).length * _amounts[i];
            }
        } else {
            // New publisher, first time publish

            publishers[msg.sender] = Publisher(
                _colors,
                _name,
                _description,
                true
            );
            weight = Floor + bytes(_name).length + bytes(_description).length;

            for (uint256 i = 0; i < _colors.length; i++) {
                require(
                    colors[_colors[i]].publisher == address(0) ||
                        colors[_colors[i]].publisher == msg.sender,
                    "Color userd"
                );
                colors[_colors[i]] = Color(_attrs[i], _amounts[i], msg.sender);
                weight += bytes(_attrs[i]).length * _amounts[i];
            }
        }

        require(msg.value >= weight * Rate, "No enought funds");
        payable(msg.sender).transfer(msg.value - weight * Rate);
        emit Published(msg.sender, _colors.length, weight);
    }

    function mint(
        address _who,
        address _to,
        uint24 _color,
        uint24 _amount
    ) external payable returns (uint256, bool) {
        require(colors[_color].publisher == _who, "Not owner");
        require(colors[_color].amount >= _amount, "No enough color items");
        bool doMint = false;

        if (!holders[_to].exists) {
            // This is first time mint to a holder
            uint24[] memory blank = new uint24[](0);

            holders[_to] = Holder(blank, blank, globalTokens.length, true);
            holders[_to].colorList.push(_color);
            holders[_to].amounts.push(_amount);
            globalTokens.push(_to);

            doMint = true;
        } else {
            // add the color to previour list
            uint256 size = holders[_to].colorList.length;
            uint256 i;
            for (i = 0; i < size; i++) {
                if (holders[_to].colorList[i] == _color) {
                    holders[_to].amounts[i] += _amount;
                    break;
                }
            }

            if (i == size) {
                // merge colors
                holders[_to].colorList.push(_color);
                holders[_to].amounts.push(_amount);
            }
        }

        colors[_color].amount -= _amount;

        uint256 weight = bytes(colors[_color].attr).length * _amount;

        emit Minted(_who, _to, colors[_color].attr, _amount, weight);

        return (weight, doMint);
    }

    function _beforeTokenTransfers(
        address _from,
        address _to,
        uint256 _tokenId
    ) external onlyOwner returns (uint256 newId) {
        Holder memory _From = holders[_from];

        if (!holders[_to].exists) {
            // This is first time mint to a holder

            holders[_to] = _From;
            globalTokens[_tokenId] = _to;
            delete holders[_from];
            return _tokenId;
        } else {
            // add the color to previour list
            Holder memory _To = holders[_to];
            for (uint256 j = 0; j < _From.colorList.length; j++) {
                uint256 i;
                uint256 size = _To.colorList.length;
                for (i = 0; i < size; i++) {
                    if (_To.colorList[i] == _From.colorList[j]) {
                        holders[_to].amounts[i] += _From.amounts[j];
                        break;
                    }
                }
                if (i == size) {
                    // merge colors
                    holders[_to].colorList.push(_From.colorList[j]);
                    holders[_to].amounts.push(_From.amounts[j]);
                }
            }
            delete globalTokens[_tokenId];
            delete holders[_from];
            return _To.globalId;
        }
    }

    function tokenURI(
        uint256 tokenId,
        bytes memory tokenShowName,
        bytes memory childrenMeta
    ) public view returns (string memory) {
        Holder memory _holder = holders[globalTokens[tokenId]];
        uint256 length = _holder.colorList.length;
        bytes memory _traits = "";

        for (uint256 i = 0; i < length; ++i) {
            Color memory _color = colors[_holder.colorList[i]];
            _traits = abi.encodePacked(
                '{"trait_type": "',
                publishers[_color.publisher].name,
                '", "value": "',
                _color.attr,
                bytes(uint256(_holder.amounts[i]).toString()),
                '"},'
            );
        }

        if (length > 0 && childrenMeta.length == 0) {
            // remove the last ','
            assembly {
                mstore(_traits, sub(mload(_traits), 1))
            }
        } else {
            _traits = abi.encodePacked(_traits, childrenMeta);
        }

        return
            Metadata.uri(
                tokenId,
                tokenShowName,
                length,
                Metadata.svgImage(_holder.colorList, _holder.amounts),
                _traits
            );
    }

    // function token(uint256 tokenId) external view returns (string memory info) {
    //     address owner = globalTokens[tokenId];
    //     require(holders[owner].exists, "tokenId not exist");

    //     info = string(
    //         abi.encodePacked(
    //             "Token[",
    //             tokenId.toString(),
    //             '] \nOwner: "',
    //             Strings.toHexString(uint256(uint160(owner)), 20),
    //             '" \n'
    //         )
    //     );

    //     uint256 size = holders[owner].colorList.length;
    //     for (uint256 i = 0; i < size; i++) {
    //         Color memory _color = colors[holders[owner].colorList[i]];

    //         info = string(
    //             abi.encodePacked(
    //                 info,
    //                 publishers[_color.publisher].name,
    //                 ".",
    //                 _color.attr,
    //                 " (color #",
    //                 Metadata.toHLHexString(holders[owner].colorList[i]),
    //                 "): ",
    //                 uint256(holders[owner].amounts[i]).toString(),
    //                 "\n"
    //             )
    //         );
    //     }
    // }

    // function publisher(address _p) external view returns (string memory info) {
    //     if (!publishers[_p].exists) {
    //         return "No publisher found";
    //     }
    //     info = string(
    //         abi.encodePacked(
    //             "Publisher: ",
    //             publishers[_p].name,
    //             " \nDescription: ",
    //             publishers[_p].description,
    //             "\n"
    //         )
    //     );
    //     uint256 size = publishers[_p].colorList.length;
    //     for (uint256 i = 0; i < size; i++) {
    //         uint24 _colorValue = publishers[_p].colorList[i];
    //         Color memory _color = colors[_colorValue];

    //         info = string(
    //             abi.encodePacked(
    //                 info,
    //                 _color.attr,
    //                 " (rgb ",
    //                 uint256(_colorValue).toHexString(),
    //                 "): ",
    //                 uint256(_color.amount).toString(),
    //                 "\n"
    //             )
    //         );
    //     }
    // }

    function publisher(address _who) external view returns (Publisher memory) {
        return publishers[_who];
    }

    function isHolder(address _who) external view returns (bool) {
        return holders[_who].exists;
    }

    function holder(address _who) external view returns (Holder memory) {
        return holders[_who];
    }

    function holder(uint256 tokenId) external view returns (address) {
        return globalTokens[tokenId];
    }

    function holder(uint24 colorsFilter)
        external
        view
        returns (address[] memory _holders)
    {
        uint256 size = globalTokens.length;
        address[] memory _buffer = new address[](size);
        uint256 _pointer = 0;

        for (uint256 i = 0; i < size; i++) {
            Holder memory _holder = holders[globalTokens[i]];

            for (uint256 j = 0; j < _holder.colorList.length; j++) {
                if (colorsFilter == _holder.colorList[j]) {
                    _buffer[_pointer++] = globalTokens[i];
                    break;
                }
            }
        }

        _holders = new address[](_pointer);
        while (_pointer > 0) {
            _holders[_pointer - 1] = _buffer[_pointer - 1];
            _pointer--;
        }
    }

    function color(uint24 _value) external view returns (Color memory) {
        return colors[_value];
    }

    function withdraw(address payable _who) external onlyOwner {
        _who.transfer(address(this).balance);
    }

    function setPrice(uint256 _Floor, uint256 _Rate) external onlyOwner {
        Rate = _Rate;
        Floor = _Floor;
    }
}


// Generated by /Users/iwan/work/brownie/icolors/scripts/functions.py