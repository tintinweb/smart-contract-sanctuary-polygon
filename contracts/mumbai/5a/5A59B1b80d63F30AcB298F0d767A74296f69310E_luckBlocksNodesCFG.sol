// SPDX-License-Identifier: GNU 
/* <Luckblocks - Decentralized Raffle Lotteries on Blockchain.>
    Copyright (C) 2023  t.me/WaLsh_P (kristim.org)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    see <https://www.gnu.org/licenses/>. */
    
pragma solidity ^0.7.6;


import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/introspection/IERC165.sol";
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IIERC721eceiver-onIERC721eceived}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IIERC721eceiver-onIERC721eceived}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
// 
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


/*
interface Iluckblocks {
    
    function getLatestPrice() external view returns (uint);    
    function amountOfRegisters() external view returns(uint);
    function currentJackpotInWei() external view returns(uint256);
    function autoSpinTimestamp() external view returns(uint256);
    function getJackpotWinnerByLotteryId(uint256 _requestCounter) external view returns (address);
    function ourLastWinner() external view returns(address);
    function ourLastJackpotWinner() external view returns(address);
    function lastJackpotTimestamp() external view returns(uint256);

}
*/

interface Iluckblocks { 
    function autoSpinTimestamp() external view returns(uint256);
}


// Staking Smart contract that receives the luckblockNodes NFTs and works with the lotteries for automation and rewards
contract luckBlocksNodesCFG is Ownable,ReentrancyGuard {
  using SafeMath for uint256;

  IERC721 lbNodesNFTs;
  Iluckblocks lbcontract;

    // define NFT struct
    struct Node {
      address owner;
      uint256 totalProfit;
    }

   //
   address lbbtc;
   address lbkrstm;
   address lbeth;
   address lbmatic;
   address lbbtcw;
   address lbkrstmw;
   address lbethw;
   address lbmaticw;
   //

   // Common NFTNodes queue
   uint[] public activenodes;
   uint[] public waitingnodes;

   // Golden NFTNodes queue
   uint[] public activenodesG;
   uint[] public waitingnodesG;
    
   // tokenId to Node Info
   mapping(uint256 => Node) public nodes;

  // Mapping of active node staker address
  mapping(address => bool) public activeCAddress;
  mapping(address => bool) public activeGAddress;

  // Events list
  event NftStaked(uint256 indexed tokenId, address indexed owner);
  event NftUnstaked(uint256 indexed tokenId, address indexed owner);
  event NftRewarded(uint256 indexed tokenId, uint256 lottery, uint256 amount, address indexed owner);
  event UserActivated(uint256[] nodes, address indexed owner, uint256 weekly);

  // initialize contract while deployment
    constructor (address _lbnodes){
     
          lbNodesNFTs = IERC721(_lbnodes);

    }


    // Move the last element to the deleted spot.
    // Remove the last element.
    function clearActiveElement(uint index) internal {
        activenodes[index] = activenodes[activenodes.length-1];
        activenodes.pop();
    }

    function clearWaitingElement(uint index) internal {
        waitingnodes[index] = waitingnodes[waitingnodes.length-1];
        waitingnodes.pop();
    }
    
    function clearActiveElementG(uint index) internal {
        activenodesG[index] = activenodesG[activenodesG.length-1];
        activenodesG.pop();
    }

    function clearWaitingElementG(uint index) internal {
        waitingnodesG[index] = waitingnodesG[waitingnodesG.length-1];
        waitingnodesG.pop();
    }

    function stake(uint256 tokenId) public virtual nonReentrant {
        
        require(lbNodesNFTs.ownerOf(tokenId) == msg.sender, "caller is not owner nor approved");

        //Stake token to participate in the node automation rewards
        // Transfer the token from the wallet to the Smart contract
        lbNodesNFTs.transferFrom(msg.sender,address(this),tokenId);

        // Create node Token configuration
        Node memory node = Node(msg.sender, 0);

        nodes[tokenId] = node;        
        
        activeCAddress[msg.sender] = false;
        activeGAddress[msg.sender] = false;
        
        emit NftStaked(tokenId, msg.sender);

    }

    function unstake(uint256 tokenId) public virtual nonReentrant {
              
        // Wallet must own the token they are trying to withdraw
        require(nodes[tokenId].owner == msg.sender, "You don't own this token!");

        if(tokenId < 11){
          // Find the index of this token id in the nodes array
          uint256 index = 0;
          uint[] memory _activenodes = activenodesG;
          uint[] memory _waitingnodes = waitingnodesG;

          bool didDisabled = false;

          for (uint256 i = 0; i < _activenodes.length; i++) {
              if (
                  _activenodes[i] == tokenId
              ) {
                  index = i;
                  clearActiveElementG(index);
                  // Update the mapping of the tokenId to the be address(0) to indicate that the token is no longer staked
                  Node memory node = Node(address(0), 0);
                  nodes[tokenId] = node;
                  didDisabled = true;
              }
          }
          
          if(didDisabled == false){
            for (uint256 i = 0; i < _waitingnodes.length; i++) {
                if (
                    _waitingnodes[i] == tokenId
                ) {
                    index = i;
                    clearWaitingElementG(index);
                    // Update the mapping of the tokenId to the be address(0) to indicate that the token is no longer staked
                    Node memory node = Node(address(0), 0);
                    nodes[tokenId] = node;
                }
            }
          }
          
          activeGAddress[msg.sender] == false;

        } else{
          // Find the index of this token id in the nodes array
          uint256 index = 0;
          uint[] memory _activenodes = activenodes;
          uint[] memory _waitingnodes = waitingnodes;

          bool didDisabled = false;

          for (uint256 i = 0; i < _activenodes.length; i++) {
              if (
                  _activenodes[i] == tokenId
              ) {
                  index = i;
                  clearActiveElement(index);
                  // Update the mapping of the tokenId to the be address(0) to indicate that the token is no longer staked
                  Node memory node = Node(address(0), 0);
                  nodes[tokenId] = node;
                  didDisabled = true;
              }
          }
          
          if(didDisabled == false){
            for (uint256 i = 0; i < _waitingnodes.length; i++) {
                if (
                    _waitingnodes[i] == tokenId
                ) {
                    index = i;
                    clearWaitingElement(index);
                    // Update the mapping of the tokenId to the be address(0) to indicate that the token is no longer staked
                    Node memory node = Node(address(0), 0);
                    nodes[tokenId] = node;
                }
            }
          }
          activeCAddress[msg.sender] == false;
       }
        // Transfer the token back to the withdrawer
        lbNodesNFTs.transferFrom(address(this), msg.sender, tokenId);

        emit NftUnstaked(tokenId, msg.sender);

    }

   function getUserActivation(address _caller,uint weekly) external view returns (bool) {
      
      if(weekly == 1){
        return activeGAddress[_caller];
      }else if (weekly == 0){
        return activeCAddress[_caller];
      }

   }

   function activateNodes(address caller, uint256[] calldata _nodes , uint lottery,uint weekly) external {
        

        if(lottery == 1){
          if(weekly == 0){
          lbcontract = Iluckblocks(lbbtc);
          } else{
          lbcontract = Iluckblocks(lbbtcw);
          }
        } else if (lottery == 2){
          if(weekly == 0){
          lbcontract = Iluckblocks(lbeth);
          } else{
          lbcontract = Iluckblocks(lbethw);
          }
        } else if (lottery == 3){
          if(weekly == 0){
          lbcontract = Iluckblocks(lbmatic);
          } else{
          lbcontract = Iluckblocks(lbmaticw);
          }
        } else if (lottery == 4){
          if(weekly == 0){
          lbcontract = Iluckblocks(lbkrstm);
          } else{
          lbcontract = Iluckblocks(lbkrstmw);
          }
        }

        if(weekly == 1){
        

           uint[] memory _activenodes = activenodesG;
           uint[] memory _waitingnodes = waitingnodesG;

            for (uint i = 0; i < _nodes.length; i++) {
               
                require(_nodes[i] < 11,"Your NFTNode is not a golden type!");

                if (caller == nodes[_nodes[i]].owner) {
                    // Find the index of this token id in the nodes array to reset user list in case already active with others nodes
                  uint256 index = 0;
                  for (uint t = _activenodes.length; t > 0; t--) {

                      if (
                          _activenodes[t-1] == _nodes[i]
                      ) {
                          index = t-1;
                          clearActiveElementG(index);
                      }
                  }
                  
                  for (uint y = _waitingnodes.length; y > 0; y--) {
                      if (
                          _waitingnodes[y-1] == _nodes[i]
                      ) {
                          index = y-1;
                          clearWaitingElementG(index);
                      }
                  }

                    // Add the token to the waitingQueue Array
                    waitingnodesG.push(_nodes[i]);
                    //activate adress state
                    activeGAddress[caller] = true;
                }
            }
        

        } else if (weekly == 0){
              
            uint[] memory _activenodes = activenodes;
            uint[] memory _waitingnodes = waitingnodes;

            for (uint i = 0; i < _nodes.length; i++) {
               
               require(_nodes[i] > 10,"Your NFTNode is not a common type!");

                if (caller == nodes[_nodes[i]].owner) {
                    // Find the index of this token id in the nodes array to reset user list in case already active with others nodes
                  uint256 index = 0;
                  for (uint t = _activenodes.length; t > 0; t--) {
                      if (
                          _activenodes[t-1] == _nodes[i]
                      ) {
                          index = t-1;
                          clearActiveElement(index);
                      }
                  }
                  
                  for (uint y = _waitingnodes.length; y > 0; y--) {
                      if (
                          _waitingnodes[y-1] == _nodes[i]
                      ) {
                          index = y-1;
                          clearWaitingElement(index);
                      }
                  }

                    // Add the token to the waitingQueue Array
                    waitingnodes.push(_nodes[i]);
                    //activate adress state
                    activeCAddress[caller] = true;
                }
            }
        
        }
        emit UserActivated(_nodes, caller , weekly);
   }

  function resetQueue(uint lottery, uint weekly) external {
        

        if(lottery == 1){
          if(weekly == 0){
          lbcontract = Iluckblocks(lbbtc);
          } else{
          lbcontract = Iluckblocks(lbbtcw);
          }
        } else if (lottery == 2){
          if(weekly == 0){
          lbcontract = Iluckblocks(lbeth);
          } else{
          lbcontract = Iluckblocks(lbethw);
          }
        } else if (lottery == 3){
          if(weekly == 0){
          lbcontract = Iluckblocks(lbmatic);
          } else{
          lbcontract = Iluckblocks(lbmaticw);
          }
        } else if (lottery == 4){
          if(weekly == 0){
          lbcontract = Iluckblocks(lbkrstm);
          } else{
          lbcontract = Iluckblocks(lbkrstmw);
          }
        }


      if(weekly == 1){
        require(block.timestamp > lbcontract.autoSpinTimestamp() + 605100,"autoSpin parameters not met");
        //send the waiting nodes to the active nodes array and delist the active stucked nodes
        uint[] memory _activenodes = activenodesG;
        uint[] memory _waitingnodes = waitingnodesG;

        for(uint a = _activenodes.length; a > 0; a--){
          
          uint256 node = _activenodes[a-1];

          address ownerOfNode = nodes[node].owner;

          //activate adress state
          activeGAddress[ownerOfNode] = false;

          clearActiveElementG(a-1);

        }
        
        
        for(uint i = _waitingnodes.length; i > 0; i--){
          
          uint256 nodeId = _waitingnodes[i-1];

          clearWaitingElementG(i-1);

          activenodesG.push(nodeId);

        }

      } else if (weekly == 0){

        require(block.timestamp > lbcontract.autoSpinTimestamp() + 86700,"autoSpin parameters not met");
        //send the waiting nodes to the active nodes array and delist the active stucked nodes
        uint[] memory _activenodes = activenodes;
        uint[] memory _waitingnodes = waitingnodes;

        for(uint a = _activenodes.length; a > 0; a--){
          
          uint256 node = _activenodes[a-1];

          address ownerOfNode = nodes[node].owner;

          //activate adress state
          activeCAddress[ownerOfNode] = false;

          clearActiveElement(a-1);

        }

        for(uint i = _waitingnodes.length; i > 0; i--){
          
          uint256 nodeId = _waitingnodes[i-1];

          clearWaitingElement(i-1);

          activenodes.push(nodeId);

        }
     }
  }

   function updateNodeInfo(address caller, uint256 reward, uint weekly,uint lottery) external returns(bool success) {
        
        if(lottery == 1){
          if(weekly == 0){
          lbcontract = Iluckblocks(lbbtc);
          } else{
          lbcontract = Iluckblocks(lbbtcw);
          }
        } else if (lottery == 2){
          if(weekly == 0){
          lbcontract = Iluckblocks(lbeth);
          } else{
          lbcontract = Iluckblocks(lbethw);
          }
        } else if (lottery == 3){
          if(weekly == 0){
          lbcontract = Iluckblocks(lbmatic);
          } else{
          lbcontract = Iluckblocks(lbmaticw);
          }
        } else if (lottery == 4){
          if(weekly == 0){
          lbcontract = Iluckblocks(lbkrstm);
          } else{
          lbcontract = Iluckblocks(lbkrstmw);
          }
        }


        // pseudo random as the random result is not crucial for anything
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(
                    block.number + 1000,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this),
                    block.number - 1000
                )
            )
        );

      if(weekly == 1){
       require(block.timestamp > lbcontract.autoSpinTimestamp() + 604800,"autoSpin parameters not met");

          //change from active to the waiting queue
          if(activenodesG.length > 0){

              uint256 randomIndex = randomNum % activenodesG.length;

              // get choosen node infos
              uint256 choosenNode = activenodesG[randomIndex];

              Node memory selectedNode = nodes[choosenNode];

              address ownerOfNode = selectedNode.owner;

              require(ownerOfNode == caller , "the caller setup is not the owner of the token");

              selectedNode.totalProfit += reward;        

              nodes[choosenNode] = selectedNode;

              clearActiveElementG(randomIndex);

              waitingnodesG.push(choosenNode);

              emit NftRewarded(choosenNode, lottery, reward, ownerOfNode);

              return true;


          } else if(waitingnodesG.length > 0) {
            //send the waiting nodes to the active nodes array

              uint256 randomIndex = randomNum % waitingnodesG.length;

              // get choosen node infos
              uint256 choosenNode = waitingnodesG[randomIndex];
              
              Node memory selectedNode = nodes[choosenNode];

              address ownerOfNode = selectedNode.owner;

              require(ownerOfNode == caller , "the caller setup is not the owner of the token");

              selectedNode.totalProfit += reward;        

              nodes[choosenNode] = selectedNode;

              uint[] memory _waitingnodes = waitingnodesG;

              for(uint i = _waitingnodes.length; i > 0; i--){
                
                uint256 nodeId = _waitingnodes[i-1];

                clearWaitingElementG(i-1);

                activenodesG.push(nodeId);

              }
            
            emit NftRewarded(choosenNode, lottery, reward, ownerOfNode);

            return true;

          } else {

            return false;

          }

      } else if(weekly == 0){
       require(block.timestamp > lbcontract.autoSpinTimestamp() + 86400,"autoSpin parameters not met");

      //change from active to the waiting queue
      if(activenodes.length > 0){

          uint256 randomIndex = randomNum % activenodes.length;

          // get choosen node infos
          uint256 choosenNode = activenodes[randomIndex];
          
            Node memory selectedNode = nodes[choosenNode];

            address ownerOfNode = selectedNode.owner;

            require(ownerOfNode == caller , "the caller setup is not the owner of the token");

            selectedNode.totalProfit += reward;        

            nodes[choosenNode] = selectedNode;     

          clearActiveElement(randomIndex);

          waitingnodes.push(choosenNode);

          emit NftRewarded(choosenNode, lottery, reward, ownerOfNode);

          return true;


      } else if(waitingnodes.length > 0) {
        //send the waiting nodes to the active nodes array

          uint256 randomIndex = randomNum % waitingnodes.length;

          // get choosen node infos
         uint256 choosenNode = waitingnodes[randomIndex];
          
            Node memory selectedNode = nodes[choosenNode];

            address ownerOfNode = selectedNode.owner;

            require(ownerOfNode == caller , "the caller setup is not the owner of the token");

            selectedNode.totalProfit += reward;        

            nodes[choosenNode] = selectedNode;

            uint[] memory _waitingnodes = waitingnodes;

          for(uint i = _waitingnodes.length; i > 0; i--){
            
            uint256 nodeId = _waitingnodes[i-1];

            clearWaitingElement(i-1);

            activenodes.push(nodeId);

          }
        
        emit NftRewarded(choosenNode, lottery, reward, ownerOfNode);

        return true;

      } else {

        return false;

      }

    }
      
   }

   function setlottoaddresses (address _lbbtc,address _lbkrstm, address _lbeth, address _lbmatic) public onlyOwner {
    
    lbbtc = _lbbtc;
    lbkrstm = _lbkrstm;
    lbeth = _lbeth;
    lbmatic = _lbmatic;

   }

   function setlottoweekly (address _lbbtcw,address _lbkrstmw, address _lbethw, address _lbmaticw) public onlyOwner {

    lbbtcw = _lbbtcw;
    lbkrstmw = _lbkrstmw;
    lbethw = _lbethw;
    lbmaticw = _lbmaticw;

   }
   //Info Functions

   function getWaitingNodes(bool _golden) external view returns(uint256[] memory){

        if(_golden == true){
         return waitingnodesG;
        }else{
         return waitingnodes;
        }
   }

    function getActiveNodes(bool _golden) external view returns(uint256[] memory){

        if(_golden == true){
         return activenodesG;
        }else{
         return activenodes;
        }
   }

    function getNodeStatus(uint nftId) public view returns(string memory){
        
        bool status = false;

        if(nftId > 10){

          for(uint i = 0; i < activenodes.length; i++){

            uint256 nodeId = activenodes[i];

            if(nodeId == nftId){
                status = true;
            }

          }

        } else{
          for(uint i = 0; i < activenodesG.length; i++){

            uint256 nodeId = activenodesG[i];

            if(nodeId == nftId){
                status = true;
            }

          }
        }

        if(status == true){
          return "inActive";
        } else{
          return "notInActive";
        }

   }

  function getStakedNodesFromUser(address _wallet) public view returns (uint256[] memory) {
      uint256[] memory nodeArray = new uint256[](50); // Initialize the array with a fixed size
      uint256 count = 0; // Variable to keep track of the number of matched nodes
      
      for (uint256 i = 0; i < 50; i++) {
            
            Node memory checkeddNode = nodes[i];

            address ownerOfNode = checkeddNode.owner;

          if (ownerOfNode == _wallet) {
              nodeArray[count] = i;
              count++;
          }
      }

      // Trim the array to remove unused slots
      uint256[] memory trimmedArray = new uint256[](count);
      for (uint256 i = 0; i < count; i++) {
          trimmedArray[i] = nodeArray[i];
      }

      return trimmedArray;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}