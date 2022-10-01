/**
 *Submitted for verification at polygonscan.com on 2022-09-30
*/

pragma solidity ^0.8.16;
pragma experimental ABIEncoderV2;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract getPairsReserves {

    address public creator = msg.sender;
    mapping(address => bool) private Pairs;
    address[] listOfPairs;


    mapping(address => bool) private Owners;
    address[] listOfOwners;

    struct allReserveData2 {
        uint112 reserve0;
        uint112 reserve1;
    }

    struct allReserveData {
        address pair;
        uint112 reserve0;
        uint112 reserve1;
    }
    struct allReserveData3 {
        address pair;
        uint112 reserve0;
        uint112 reserve1;
        uint32 blockTimestampLast;
    }
    function getAllReservesFromList(address [] memory pairsList) public view returns(allReserveData[] memory a){
        a = new allReserveData[](pairsList.length);
        for (uint i=0; i < pairsList.length; i++) {
            (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pairsList[i]).getReserves();
            // a[i] = abi.encode(pairsList[i],reserve0,reserve1);
            a[i] = allReserveData(pairsList[i],reserve0,reserve1);
        }
        return(a);
    }
    // function getAllReservesFromList(address [] memory pairsList) public view returns(bytes[] memory a){
    //     a = new bytes[](pairsList.length);
    //     for (uint i=0; i < pairsList.length; i++) {
    //         (uint reserve0, uint reserve1, ) = IUniswapV2Pair(pairsList[i]).getReserves();
    //         a[i] = abi.encode(pairsList[i],reserve0,reserve1);
    //     }
    //     return(a);
    // }

    function getAllReservesFromListWithTime(address [] memory pairsList) public view returns(allReserveData3[] memory a){
        a = new allReserveData3[](pairsList.length);
        
        for (uint32 i=0; i < pairsList.length; i++) {
            (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast ) = IUniswapV2Pair(pairsList[i]).getReserves();
            // a[i] = abi.encode(pairsList[i],reserve0,reserve1);
            a[i] = allReserveData3(pairsList[i],reserve0,reserve1,blockTimestampLast);
        }
        return(a);
    }
    function getAllReserves(uint from,uint to) public view returns(bytes[] memory a){
        a = new bytes[](to-from);
        for (uint i=0; i < to-from; i++) {
            (uint reserve0, uint reserve1, ) = IUniswapV2Pair(listOfPairs[i+from]).getReserves();

            a[i] = abi.encode(listOfPairs[i+from],reserve0,reserve1);
        }
        return(a);
    }

    function getAllReservesStruct(uint32 from,uint32 to) public view returns(allReserveData[] memory a){
        a = new allReserveData[](to-from);
        for (uint32 i=0; i < to-from; i++) {
            (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(listOfPairs[i+from]).getReserves();

            a[i] = allReserveData(listOfPairs[i+from],reserve0,reserve1);
        }
        return(a);
    }


    function getAllReservesStructAndTime(uint32 from,uint32 to, uint32 Timestamp) public view returns(allReserveData[] memory a){
        a = new allReserveData[](30);
        uint32 j = 0;
        for (uint32 i=0; i < to-from; i++) {
            (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast ) = IUniswapV2Pair(listOfPairs[i+from]).getReserves();
            if (Timestamp == blockTimestampLast){
                a[j] = allReserveData(listOfPairs[i+from],reserve0,reserve1);
                j++ ;
            }
        }
        return(a);
    }
    function getAllReservesStructAndTimeLimi(uint32 from,uint32 to, uint32 Timestamp) public view returns(allReserveData[] memory b){
        allReserveData[] memory a = new allReserveData[](30);
        uint32 j = 0;
        for (uint32 i=0; i < to-from; i++) {
            (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast ) = IUniswapV2Pair(listOfPairs[i+from]).getReserves();
            if (Timestamp == blockTimestampLast){
                a[j] = allReserveData(listOfPairs[i+from],reserve0,reserve1);
                j++ ;
            }
        }
        b = new allReserveData[](j);
        if (j > 0){
            for (uint32 k=0; k < j; k++) {
                b[k] = a[k];
            }
        }
    }

    function getAllReservesStruct2(uint32 from,uint32 to) public view returns(uint, allReserveData2[] memory a){
        a = new allReserveData2[](to-from);
        for (uint32 i=0; i < to-from; i++) {
            (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(listOfPairs[i+from]).getReserves();

            a[i] = allReserveData2(reserve0,reserve1);
        }
        return(from, a);
    }
   

    function getCustomPairs(uint from,uint to) public view returns(address[] memory a){
        a = new address[](to-from);
        for (uint i=0; i < to-from; i++) {
            a[i] = listOfPairs[i+from];
        }
        return(a);
    }

    function getAllPairs() public view returns(address[] memory a){
        a = new address[](listOfPairs.length);
        for (uint i=0; i < listOfPairs.length; i++) {
            a[i] = listOfPairs[i];
        }
        return(a);
    }

    function check_if_supported_Pair_in(address _pair)  public view returns(bool flag){
        uint8 i = 0;
        flag = false;
        while(i<listOfPairs.length && flag==false){
            if(listOfPairs[i] == _pair){
                flag=true;
            }
            i++;
        }
    }

    modifier onlyCreator{
        require(msg.sender==creator, "Sorry: Access Denied!");
        _;
    }
    modifier onlyOwner{
        require(msg.sender==creator||Owners[msg.sender], "Sorry: Access Denied!");
        _;
    }

    function addPairs(address[] calldata _pairs) onlyOwner external {
        for(uint8 i=0; i<_pairs.length; i++){
            if(Pairs[_pairs[i]] == false){
                Pairs[_pairs[i]] = true;
                listOfPairs.push(_pairs[i]);
            }
        }
    }

    function deletePair(address _pair) internal {
        uint8 i = 0;
        bool flag = false;
        while(i<listOfPairs.length && flag==false){
            if(listOfPairs[i] == _pair){
                listOfPairs[i] = listOfPairs[listOfPairs.length-1];
                listOfPairs.pop();
                flag=true;
            }
            i++;
        }
    }

    function removePairs(address[] calldata _pairs) onlyOwner external {
        for(uint8 i=0; i<_pairs.length; i++){
            if(Pairs[_pairs[i]]){
                Pairs[_pairs[i]] = false;
                deletePair(_pairs[i]);
            }
        }
    }

    function totalPairs()  public view returns (uint) {
        return listOfPairs.length;
    }

    function addNewOwner(address[] calldata _owner) onlyCreator external {
        for(uint8 i=0; i<_owner.length; i++){
            if(Owners[_owner[i]] == false){
                Owners[_owner[i]] = true;
                listOfOwners.push(_owner[i]);
            }
        }
    }

    function deleteOwner(address _owner) internal {
        uint8 i = 0;
        bool flag = false;
        while(i<listOfOwners.length && flag==false){
            if(listOfOwners[i] == _owner){
                listOfOwners[i] = listOfOwners[listOfOwners.length-1];
                listOfOwners.pop();
                flag=true;
            }
            i++;
        }
    }

    function removeOwner(address[] calldata _owner) onlyCreator external {
        for(uint8 i=0; i<_owner.length; i++){
            if(Owners[_owner[i]]){
                Owners[_owner[i]] = false;
                deleteOwner(_owner[i]);
            }
        }
    }

    function showOwners() onlyCreator external view returns(address[] memory){
        return listOfOwners;
    }

}