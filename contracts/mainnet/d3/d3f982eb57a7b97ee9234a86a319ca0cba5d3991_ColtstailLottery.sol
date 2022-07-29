/**
 *Submitted for verification at polygonscan.com on 2022-07-29
*/

/**
 *Submitted for verification at polygonscan.com on 2022-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract ColtstailLottery is Ownable{
    uint[] public indices;
    
    uint nonce;

    //入围名单
    mapping(string => bool) shortlistMap;
    string[] public shortlist;

    //中奖名单(下标)
    uint[] public list;
    //中奖名单(账号)
    string[] public winnerList;

    //添加入围名单
    function addShortlist(string[] memory _list) public onlyOwner {
        for(uint i=0;i<_list.length;i++){
            if(!shortlistMap[_list[i]]){
                shortlistMap[_list[i]] = true;
                shortlist.push(_list[i]);
            }
        }
    }

    //移除入围名单
    function removeShortlist() public onlyOwner {
        remove(1);
    }

    //获取入围名单
    function getShortlist() public view returns( string[] memory){
        return shortlist;
    }

    function remove(uint _index) public onlyOwner{
        require(_index < shortlist.length, "index out of bound");

        for (uint i = _index; i < shortlist.length - 1; i++) {
            shortlist[i] = shortlist[i + 1];
        }
        shortlist.pop();
    }

    //重置开奖数据
    function reset() public onlyOwner {
        nonce = 0;
        for(uint i=0;i<list.length;i++){
            indices[list[i]-1]=0;
            //indices[randomIndex()] = 0;
        }
        list = new uint[](list.length);
        winnerList = new string[](list.length);
    }

    function start(uint _num) public onlyOwner returns(uint[] memory,string[] memory) {
        indices = new uint[](shortlist.length);
        list = new uint[](_num);
        winnerList = new string[](_num);
        
        for(uint i=0;i<_num;i++){
            list[i]=randomIndex();
            winnerList[i]= string(shortlist[list[i]]);
            //indices[randomIndex()] = 0;
        }
        
        return (list,winnerList);
    }

    

    function getWinner() public view returns( uint[] memory,string[] memory){
        return (list,winnerList);
    }

    function getIndex() public view returns( uint[] memory){
        return indices;
    }

    function randomIndex() private returns (uint) {
        uint totalSize = shortlist.length - nonce;
        uint index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
        uint value = 0;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        if (indices[totalSize - 1] == 0) {
            indices[index] = totalSize - 1;
        } else {
            indices[index] = indices[totalSize - 1];
        }
        nonce++;
        return value+1;
    }
    
}