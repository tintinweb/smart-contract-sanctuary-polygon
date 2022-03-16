/**
 *Submitted for verification at polygonscan.com on 2022-03-15
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract Controllable is Ownable {
    mapping(address => bool) internal _controllers;

    modifier onlyController() {
        require(
            _controllers[msg.sender] == true || address(this) == msg.sender,
            "Controllable: caller is not a controller"
        );
        _;
    }

    function addController(address _controller) external onlyOwner {
        _controllers[_controller] = true;
    }

    function delController(address _controller) external onlyOwner {
        delete _controllers[_controller];
    }

    function disableController(address _controller) external onlyOwner {
        _controllers[_controller] = false;
    }

    function isController(address _address)
        external
        view
        returns (bool allowed)
    {
        allowed = _controllers[_address];
    }

    function relinquishControl() external onlyController {
        delete _controllers[msg.sender];
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

interface IToken {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function mint(address to, uint256 amount) external;
}

interface INft {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract Stake is Controllable {
    address public tokenAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public royaltyFunds = 0;

    uint256 public totalStakedNfts = 0;

    address[] holders;

    uint256[] runWayTime;

    uint256[] prizes;

    address[] nftContracts;
    mapping(address => uint256) nftContractToIndex;
    
    mapping(address => mapping(uint256 => uint256)) addressAndIndexToNftToken;

    struct HolderData {
        uint256[] stakedTokens;
        mapping (uint256=>uint256) tokenToTime;
        mapping (uint256=>uint256) tokenToIndex;
    }

    mapping (address=> mapping(address=>HolderData)) holder;

    mapping (address=>uint256) addressToIndex;

    function stake(address _address, uint256 _tokenId) public onlyOwner {
        require(nftContracts[nftContractToIndex[_address] - 1]  == _address, "This contract doesn't exist");
        require(nftContractToIndex[_address] != 0, "This contract doesn't exist");
        
        INft nft = INft(_address);
        require(nft.ownerOf(_tokenId) == msg.sender, "You are not the owner of this token id");

        //

        nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        if(checkIfHolderUnique(msg.sender) == false) {
            holders.push(msg.sender);
            addressToIndex[msg.sender] = holders.length;
        }        

        holder[_address][msg.sender].stakedTokens.push(_tokenId);
        holder[_address][msg.sender].tokenToIndex[_tokenId] = holder[_address][msg.sender].stakedTokens.length;
        holder[_address][msg.sender].tokenToTime[_tokenId] = block.timestamp;

        totalStakedNfts++;
    } // Done!

    function unStake(address _address, uint256 _tokenId) public onlyOwner {
        require(holder[_address][msg.sender].tokenToTime[_tokenId] >= holder[_address][msg.sender].tokenToTime[_tokenId] + runWayTime[nftContractToIndex[_address] - 1]);
        require(nftContracts[nftContractToIndex[_address] - 1]  == _address, "This contract doesn't exist");
        require(nftContractToIndex[_address] != 0, "This contract doesn't exist");
        
        INft nft = INft(_address);
        require(holder[_address][msg.sender].stakedTokens[holder[_address][msg.sender].tokenToIndex[_tokenId] - 1] == _tokenId, "You are not the owner of this token id");
        
        IToken token = IToken(tokenAddress);

        //

        nft.safeTransferFrom(address(this), msg.sender, _tokenId);

        holder[_address][msg.sender].stakedTokens[holder[_address][msg.sender].tokenToIndex[_tokenId] - 1] = holder[_address][msg.sender].stakedTokens[holder[_address][msg.sender].stakedTokens.length - 1];
        holder[_address][msg.sender].tokenToIndex[holder[_address][msg.sender].stakedTokens.length - 1] = holder[_address][msg.sender].tokenToIndex[_tokenId];
        holder[_address][msg.sender].stakedTokens.pop();
        holder[_address][msg.sender].tokenToIndex[_tokenId] = 0;

        token.transfer(msg.sender, prizes[nftContractToIndex[_address] - 1]);

        totalStakedNfts--;

        
        bool check = false;

        for (uint256 i = 0; i < nftContracts.length; i++) {
            if (getStakedTokensForSpecificHolderAndSpecificNftContract(nftContracts[i], msg.sender).length == 0) {
                check = true;
            } else {
                check = false;
                break;
            }
        }

        if (check == true) {
            holders[addressToIndex[msg.sender] - 1] = holders[holders.length - 1];
            addressToIndex[holders[holders.length - 1]] = addressToIndex[msg.sender];
            holders.pop();
            addressToIndex[msg.sender] = 0;
        }
    } // Done!

    // Internal functions

    function checkIfHolderUnique(address _address) internal view returns(bool){
        bool check = false;
        for (uint256 i = 0; i < holders.length; i++) {
            if(holders[i] == _address) {
                check = true;
                break;
            }
        }
        return check;
    } // Done!

    // Get functions

    function getHolders() view public returns (address[] memory) {
        return holders;        
    } // Done!

    function getStakedTokensForSpecificHolderAndSpecificNftContract(address _nftContractAddress, address _holderAddress) view public returns (uint256[] memory) {
        return holder[_nftContractAddress][_holderAddress].stakedTokens;
    } // Done!

    function getHoldersAndTheirStakedTokensForEachNftContract() view public returns (address[] memory, address[] memory, uint256[][][] memory) {
        uint256[][][] memory temporary;

        for (uint256 i = 0; i < holders.length; i++) {
            uint256[][] memory temporary2;

            for (uint256 a = 0; a < nftContracts.length; a++) {
                temporary2[a] =  holder[nftContracts[a]][holders[i]].stakedTokens;
                
            }
            
            temporary[i] = temporary2;
        }
        return (holders, nftContracts, temporary);
    } // Done!

    function getHoldersAndTheirStakedTokensForSpecificNftContract(address _nftContractAddress) view public returns (address[] memory, uint256[][] memory) {
        uint256[][] memory temporary;

        for (uint256 i = 0; i < holders.length; i++) {
            temporary[i] =  holder[_nftContractAddress][holders[i]].stakedTokens;
        }
        return (holders, temporary);
    } // Done!

    // Admin functions

    function addNftContract(address _address) public onlyOwner {
        nftContracts.push(_address);
        nftContractToIndex[_address] = nftContracts.length;
    } // Done!

    function removeNftContract(address _address) public onlyOwner {
        nftContracts[nftContractToIndex[_address] - 1] = nftContracts[nftContracts.length - 1];
        nftContractToIndex[nftContracts[nftContracts.length - 1]] = nftContractToIndex[_address];
        nftContracts.pop();
        nftContractToIndex[_address] = 0;
    } // Done!

    function setPrizesForNftContracts(address _address, uint256 _prize) public onlyOwner {
        prizes[nftContractToIndex[_address] - 1] = _prize;
    } // Done!

    function setRunWayTimeForNftContracts(address _address, uint256 _runWayTimeInDays) public onlyOwner {
        runWayTime[nftContractToIndex[_address] - 1] = _runWayTimeInDays * 1 days;
    } // Done!

    function depositFunds() public payable onlyOwner {
        royaltyFunds = msg.value;
    } // Done!

    function distributeRoyalties() public onlyOwner {
        uint256 royalty = royaltyFunds / totalStakedNfts;
        

        for (uint256 i = 0; i < holders.length; i++) { 
            uint256 nftCount = 0;

            for (uint256 a = 0; a < nftContracts.length; a++) {
                nftCount += getStakedTokensForSpecificHolderAndSpecificNftContract(nftContracts[a], holders[i]).length;
            }
            
            payable(holders[i]).transfer(royalty*nftCount);
        }

        royaltyFunds = 0;
    } // Done!

    function setTokenAddress(address _address) public onlyOwner {
        tokenAddress = _address;
    } // Done!
}