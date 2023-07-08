/**
 *Submitted for verification at polygonscan.com on 2023-07-08
*/

//SPDX-License-Identifier:None
pragma solidity>0.8.0;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    function balanceOf(address)                                         external view returns(uint);
    function ownerOf(uint)                                              external view returns(address);
    function getApproved(uint)                                          external view returns(address);
    function isApprovedForAll(address, address)                         external view returns(bool);
    function approve(address, uint)                                     external;
    function setApprovalForAll(address, bool)                           external;
    function transferFrom(address, address, uint)                       external;
    function safeTransferFrom(address, address, uint)                   external;
    function safeTransferFrom(address, address, uint, bytes calldata)   external;
}

interface IERC721Metadata {
    function name()                                                     external view returns(string memory);
    function symbol()                                                   external view returns(string memory);
    function tokenURI(uint)                                             external view returns(string memory);
}

interface IERC20 {
    function transfer(address, uint)                                    external;
    function transferFrom(address, address, uint)                       external;
    function balanceOf(address)                                         external view returns(uint);
}

contract ERC721AC is IERC721, IERC721Metadata {

    address constant                                public owner = 0x9201Ee0BfA09b00c40bE6C4854509F68B5ECdfB4;
    string constant                                 public name = "Alpha Club";
    string constant                                 public symbol = "ALC";
    mapping(uint    => address)                     public ownerOf;
    mapping(address => uint)                        public balanceOf;
    mapping(uint    => address)                     public getApproved;
    mapping(address => mapping(address => bool))    public isApprovedForAll;

    uint                                            private count;
    mapping(uint    => uint)                        private id2URI;
    mapping(uint    => string)                      private URIs;
    mapping(address => mapping(uint => uint))       private lists;

    modifier OnlyOwner() {

        assert(msg.sender == owner);
        _;

    }

    constructor() {

       URIs[1] = "ipfs://QmRPixFx2QUHWBkd4BZyw24NqW2JxG9SDS9HBjQmsSkjpy";
       _mint(msg.sender, 1);
       _mint(owner, 1);

    }

    function supportsInterface(bytes4 i) external pure returns(bool) {

        return i == type(IERC721).interfaceId || i == type(IERC721Metadata).interfaceId;

    }
    
    function tokenURI(uint id) external view returns(string memory) {

        return URIs[id2URI[id]];

    }

    function approve(address to, uint id) external {

        assert(msg.sender == ownerOf[id] || isApprovedForAll[ownerOf[id]][msg.sender]);
        emit Approval(ownerOf[id], getApproved[id] = to, id);

    }
    
    function setApprovalForAll(address to, bool bol) external {

        emit ApprovalForAll(msg.sender, to, isApprovedForAll[msg.sender][to] = bol);

    }
    
    function safeTransferFrom(address from, address to, uint id) external {

        transferFrom(from, to, id);

    }

    function safeTransferFrom(address from, address to, uint id, bytes memory) external {

        transferFrom(from, to, id);

    }

    function transferFrom(address from, address to, uint id) public { 

        address _owner = ownerOf[id];

        assert( from == _owner || 
                getApproved[id] == from || 
                isApprovedForAll[_owner][from]);
        
        unchecked {
        
           (--balanceOf[from], ++balanceOf[to], getApproved[id] = address(0));
        
            emit Approval(ownerOf[id] = to, to, id);
            emit Transfer(from, to, id);

        }
    }

    function setURIs(uint id, string calldata uri) external OnlyOwner {

        URIs[id] = uri;

    }

    function whitelist(address[] memory to, uint URIID) external OnlyOwner {

        unchecked {

            for(uint i; i < to.length; ++i) 
                if(lists[to[i]][URIID] == 0) 
                    lists[to[i]][URIID] = 1;

        }

    }

    function _mint(address to, uint URIID) private {

        unchecked {

           (ownerOf[++count], id2URI[count], lists[to][URIID]) 
                =(to, URIID, 2);
            ++balanceOf[to];

        }

        emit Transfer(address(0), to, count);

    }

    function mint(address to, uint URIID) external {

        assert(URIID > 0 && lists[to][URIID] == 1);
        _mint(to, URIID);

    }

    function mint(uint quantity) external {

        uint amount = 1e18 * quantity;

        IERC20 iERC20 = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
        iERC20.transferFrom(msg.sender, address(this), amount);
        iERC20.transferFrom(address(this), 0x2e0aCE0129E66A36cee92c5146C73Ec4874d0109, amount / 10);
        iERC20.transferFrom(address(this), owner, iERC20.balanceOf(address(this)));

        for(uint i = 0; i < quantity; i++) _mint(msg.sender, 1);

    }

}