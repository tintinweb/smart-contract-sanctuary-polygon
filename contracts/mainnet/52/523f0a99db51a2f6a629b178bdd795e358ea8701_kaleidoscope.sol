/**
 *Submitted for verification at polygonscan.com on 2022-03-07
*/

//SPDX-License-Identifier: Unlicense

//Ardi

pragma solidity 0.8.12;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

contract kaleidoscope is ERC721, Ownable {
    uint256 public maxSupply = 360;
    uint256 public numTokensMinted = 0;
    uint256 private seed;
    mapping(address => uint256) private limitPerWallets;
    uint256 limitMintPerWallet = 3;
    bool public mintislive = false;
    bool public customization = false;
    uint256 public customizePrice = 25 ether;

    constructor() ERC721("Kaleidoscope NFTs", "KSCP") Ownable() {
        seed = uint256(
            keccak256(abi.encodePacked(block.timestamp + block.difficulty))
        );
    }

    struct Atts {
        uint256 numberofpoints;
        uint256 numberofmirros;
        string linecolor;
        string backgroundcolor;
        uint256 strokewidth;
        string opacity;
        bool cropped;
    }

    mapping(uint256 => Atts) private Attributes;

    function getSVG(uint256 _tokenId) public view returns (string memory) {
        uint256 tokenId = _tokenId;
        Atts memory NewAtts = Attributes[tokenId];

        string memory gOpen = string(
            abi.encodePacked(
                '<g stroke="',
                NewAtts.linecolor,
                '" stroke-width="',
                toString(NewAtts.strokewidth),
                '" opacity="',
                NewAtts.opacity,
                '" fill="none">'
            )
        );
        string memory mainPath = "";
        uint256 rand = uint256(keccak256(abi.encodePacked(tokenId + seed)));
        uint256 x1 = (rand / 200) % 10000;
        uint256 y1 = (rand / 400) % 10000;
        string memory main1 = string(
            abi.encodePacked(
                '<path id="P" d="M',
                toString(x1),
                " ",
                toString(y1)
            )
        );

        for (uint256 i = 1; i < NewAtts.numberofpoints; i++) {
            x1 = (rand / (i + 600)) % 10000;
            y1 = (rand / (i + 800)) % 10000;
            mainPath = string(
                abi.encodePacked(mainPath, "L", toString(x1), " ", toString(y1))
            );
            x1 = (rand / (i + 1000)) % 10000;
            y1 = (rand / (i + 1200)) % 10000;
            mainPath = string(
                abi.encodePacked(mainPath, "L", toString(x1), " ", toString(y1))
            );
            x1 = (rand / (i + 1400)) % 10000;
            y1 = (rand / (i + 1600)) % 10000;
            mainPath = string(
                abi.encodePacked(mainPath, "L", toString(x1), " ", toString(y1))
            );
            x1 = (rand / (i + 1800)) % 10000;
            y1 = (rand / (i + 2000)) % 10000;
            mainPath = string(
                abi.encodePacked(mainPath, "L", toString(x1), " ", toString(y1))
            );
            x1 = (rand / (i + 2200)) % 10000;
            y1 = (rand / (i + 2400)) % 10000;
            mainPath = string(
                abi.encodePacked(mainPath, "L", toString(x1), " ", toString(y1))
            );
        }

        mainPath = string(
            abi.encodePacked("<defs>", main1, mainPath, ' Z"/></defs>')
        );

        string memory output = "";

        uint256 II = 360 / NewAtts.numberofmirros;
        for (uint256 i = 0; i < NewAtts.numberofmirros; i++) {
            output = string(
                abi.encodePacked(
                    output,
                    '<use href="#P" transform = "rotate(',
                    toString(II * (i + 1)),
                    ' 5000 5000)"/>'
                )
            );
        }

        string memory circles;
        if (NewAtts.cropped) {
            circles = string(
                abi.encodePacked(
                    '<circle cx="5000" cy="5000" r="6035" stroke="white" stroke-width="2070" fill="none"/><circle cx="5000" cy="5000" r="5000" stroke="',
                    NewAtts.linecolor,
                    '" opacity="',
                    NewAtts.opacity,
                    '" stroke-width="',
                    toString(NewAtts.strokewidth),
                    '" fill="none" />'
                )
            );
        }

        output = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 10000 10000"><rect width="10000" height="10000" style="fill:',
                NewAtts.backgroundcolor,
                '"/>',
                gOpen,
                output,
                "</g>",
                circles,
                mainPath,
                "</svg>"
            )
        );

        return output;
    }

    function getattributes(uint256 _tokenId)
        internal
        view
        returns (string memory)
    {
        uint256 tokenId = _tokenId;
        Atts memory NewAtts = Attributes[tokenId];
        string memory tt = '{"trait_type": "';

        string memory croppedS;
        if (NewAtts.cropped) {
            croppedS = "True";
        } else {
            croppedS = "False";
        }

        string memory output = string(
            abi.encodePacked(
                ', "attributes": [',
                tt,
                'Number of Points","value": "',
                toString(NewAtts.numberofpoints),
                '"}, ',
                tt,
                'Number of Mirrors","value": "',
                toString(NewAtts.numberofmirros),
                '"}, ',
                tt,
                'Stroke Color","value": "',
                NewAtts.linecolor,
                '"}, ',
                tt,
                'Background Color","value": "'
            )
        );
        output = string(
            abi.encodePacked(
                output,
                NewAtts.backgroundcolor,
                '"}, ',
                tt,
                'Stroke Width","value": "',
                toString(NewAtts.strokewidth),
                '"}, ',
                tt,
                'Opacity","value": "',
                NewAtts.opacity,
                '"}, ',
                tt,
                'Cropped","value": "',
                croppedS,
                '"}], '
            )
        );
        return output;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Kaleidoscope NFT #',
                        toString(tokenId),
                        '", "description": "Kaleidoscope NFTs are Fully-On-Chain, Customizable, unique, and Randomly generated NFTs"',
                        getattributes(tokenId),
                        '"image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(getSVG(tokenId))),
                        '"}'
                    )
                )
            )
        );
        json = string(abi.encodePacked("data:application/json;base64,", json));
        return json;
    }

    function mintART(
        address destination,
        uint256 numberofpoints,
        uint256 numberofmirros,
        string memory linecolor,
        string memory backgroundcolor,
        uint256 strokewidth,
        string memory opacity,
        bool cropped
    ) private {
        require(mintislive, "Mint has not Started Yet!");
        require(numTokensMinted + 1 < maxSupply, "Maximum Supply has been reached!");
        require(limitPerWallets[destination] < 3,"You have claimed your maximum free NFTs!");
        limitPerWallets[destination] += 1;
        uint256 tokenId = numTokensMinted + 1;
        numTokensMinted += 1;
        Attributes[tokenId] = Atts(
            numberofpoints,
            numberofmirros,
            linecolor,
            backgroundcolor,
            strokewidth,
            opacity,
            cropped
        );
        _safeMint(destination, tokenId);
    }

    function mint(
        uint256 numberofpoints,
        uint256 numberofmirros,
        string memory linecolor,
        string memory backgroundcolor,
        uint256 strokewidth,
        string memory opacity,
        bool cropped
    ) public virtual {
        mintART(
            _msgSender(),
            numberofpoints,
            numberofmirros,
            linecolor,
            backgroundcolor,
            strokewidth,
            opacity,
            cropped
        );
    }

    function setmaxSupply(uint256 newmaxSupply) public onlyOwner {
        maxSupply = newmaxSupply;
    }

    function setlimitMintPerWallet(uint256 newlimitMintPerWallet) public onlyOwner {
        limitMintPerWallet = newlimitMintPerWallet;
    }

    function setmintislive(bool newmintislive) public onlyOwner {
        mintislive = newmintislive;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    function setcustomizePrice(uint256 newcustomizePrice) public onlyOwner {
        customizePrice = newcustomizePrice;
    }
    
    function setcustomization(bool newcustomization) public onlyOwner {
        customization = newcustomization;
    }

    function customize(
        uint256 tokenId,         
        uint256 numberofpoints,
        uint256 numberofmirros,
        string memory linecolor,
        string memory backgroundcolor,
        uint256 strokewidth,
        string memory opacity,
        bool cropped) public payable {
        require(customizePrice >= msg.value, "Paid amount is incorrect!");
        require(customization, "Customization feature is not live yet!");
        require(msg.sender == ownerOf(tokenId), "You are NOT the owner of this token!");
        Attributes[tokenId] = Atts(
            numberofpoints,
            numberofmirros,
            linecolor,
            backgroundcolor,
            strokewidth,
            opacity,
            cropped
        );
    }

    function toString(uint256 value) internal pure returns (string memory) {
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
}

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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