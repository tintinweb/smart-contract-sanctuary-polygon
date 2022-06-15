/**
 *Submitted for verification at polygonscan.com on 2022-06-15
*/

// SPDX-License-Identifier: MIT

    pragma solidity ^0.8.0;

    interface IERC721Receiver {

        function onERC721Received(
            address operator,
            address from,
            uint256 tokenId,
            bytes calldata data
        ) external returns (bytes4);
    }

    contract ERC721Holder is IERC721Receiver {
    
        function onERC721Received(
            address,
            address,
            uint256,
            bytes memory
        ) public virtual override returns (bytes4) {
            return this.onERC721Received.selector;
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

        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

        constructor() {
            _transferOwnership(_msgSender());
        }

        function owner() public view virtual returns (address) {
            return _owner;
        }

        modifier onlyOwner() {
            require(owner() == _msgSender(), "Ownable: caller is not the owner");
            _;
        }

        function renounceOwnership() public virtual onlyOwner {
            _transferOwnership(address(0));
        }

    
        function transferOwnership(address newOwner) public virtual onlyOwner {
            require(newOwner != address(0), "Ownable: new owner is the zero address");
            _transferOwnership(newOwner);
        }

        function _transferOwnership(address newOwner) internal virtual {
            address oldOwner = _owner;
            _owner = newOwner;
            emit OwnershipTransferred(oldOwner, newOwner);
        }
    }

    interface IERC721 {
    
        function balanceOf(address owner) external view returns (uint256 balance);

        function ownerOf(uint256 tokenId) external view returns (address owner);

        function safeTransferFrom(
            address from,
            address to,
            uint256 tokenId,
            bytes calldata data
        ) external;

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

        function setApprovalForAll(address operator, bool _approved) external;

        function getApproved(uint256 tokenId) external view returns (address operator);

        function isApprovedForAll(address owner, address operator) external view returns (bool);

        function totalSupply() external view returns (uint);
    }

    contract CthNftStaking is Ownable, ERC721Holder {

        IERC721 public immutable NFT = IERC721(0x0cA495fCE7830aADD960f2F1EA9D0EBDdA74eE48);  //original one
        
        uint256 public duration = 3 hours;

        struct Data {
            address _person;
            uint _totalStakeNfts;
            mapping(uint => uint256) _idtotime; 
            mapping(uint => bool) _idstake;
        }
        mapping (address => Data) public stakers;
        mapping (uint => address) public TokenOwner;
        bool public paused;

        constructor() {
            _transferOwnership(0x0EAaBd0C27Bb03c67ef981F91D5b1e866780D1c9);
        }

        function stake(uint _tokenID) public {

            require(!paused,"Staking is Currently Paused due to Some Reasons!!");

            NFT.safeTransferFrom(msg.sender, address(this) , _tokenID,"");

            stakers[msg.sender]._person = msg.sender;
            
            stakers[msg.sender]._totalStakeNfts += 1;
            stakers[msg.sender]._idtotime[_tokenID] = block.timestamp + duration;  //3 hours duration  -->  to unstake that token
            stakers[msg.sender]._idstake[_tokenID] = true;
            
            TokenOwner[_tokenID] = msg.sender;

        }

        function walletOfOwner(address _owner) public view returns (uint256[] memory) {
            uint256 ownerTokenCount = stakers[_owner]._totalStakeNfts;
            uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
            uint256 currentTokenId = 0;
            uint256 ownedTokenIndex = 0;

            while (ownedTokenIndex < ownerTokenCount && currentTokenId <=  NFT.totalSupply()) {

                address currentTokenOwner = TokenOwner[currentTokenId];

                if (currentTokenOwner == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;

                    ownedTokenIndex++;
                }
                currentTokenId++;
            }
            return ownedTokenIds;
        }

        function unstake(uint _id) public {

            require(!paused,"Unstaking is Currently Paused due to Some Reasons!!");

            require(stakers[msg.sender]._idstake[_id],"Invalid id!!");
            require(block.timestamp >= stakers[msg.sender]._idtotime[_id],"Wait for atleast 3 Hours for this NFT to Unstake!!");
            
            NFT.transferFrom(address(this),msg.sender, _id);
            
            stakers[msg.sender]._idstake[_id] =  false;
            stakers[msg.sender]._totalStakeNfts -= 1;

            TokenOwner[_id] = address(0x0);

        }

        function setPaused(bool _status) external onlyOwner {
            paused = _status;
        }

        function totalStaked() public view returns (uint){
            return NFT.balanceOf(address(this));
        }

        function totalNftSupply() public view returns (uint){
            return NFT.totalSupply();
        }

    }