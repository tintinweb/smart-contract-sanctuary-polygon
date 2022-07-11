/**
 *Submitted for verification at polygonscan.com on 2022-07-10
*/

pragma solidity 0.8.7;


contract FtoWeb3
{
  
    function char(bytes1 b) internal pure returns (bytes1 c)
    {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function toString(uint256 x)internal pure returns (string memory)
    {
        if (x == 0)
        {
            return "0";
        }
        uint256 j = x;
        uint256 length;
        while (j != 0)
        {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = x;
        while (j != 0)
        {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        return string(bstr);
    }

    function toString(bool x) internal pure returns (string memory)
    {
        if(x==true)
        {
            return "true";
        }
        else
        {
            return "false";
        }
    }

    function toString(address x) internal pure returns (string memory)
    {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++)
        {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    struct FileObj
    {
        address Owner;

        string Base64Data;

        string FileName;

        uint fileSize;

        bool Completed;
    }

    int public versions=2;
    address payable public owner;
    FileObj[] fileObjs;

    constructor() payable
    {
        owner = payable(msg.sender);
    }
    



    function fileExist(uint id,uint fileObjsLength) internal pure returns (bool)
    {
        
        if(fileObjsLength>=id && fileObjsLength!=0)
            return true;
        else
            return false;

    }


    function createFile(string memory fileName,uint fileSize) public payable returns (uint)
    {
        address owner = payable(msg.sender);
  


        FileObj memory newFileObj = FileObj(owner,"",fileName,fileSize,false);

        fileObjs.push(newFileObj);

        return fileObjs.length;

    }



    function AddFile(uint id,string memory base64Data) public payable
    {

        uint ID = id ;

      
        bool IsFileExist=fileExist(id,fileObjs.length);
            
        if(IsFileExist)
        {
            address owner = payable(msg.sender);

            

            if(fileObjs[id-1].Owner==owner)
            {
                fileObjs[id-1].Base64Data=string(abi.encodePacked(fileObjs[id-1].Base64Data,base64Data));
            
            }
            else
            {
                require(false,"You are not the owner");
            }

        }
        else
        {
            require(false,"file does not exist");
        }

    }

    function getFile(uint id) public view returns(string memory)
    {
        bool IsFileExist=fileExist(id,fileObjs.length);
        

        if(IsFileExist)
        {
            return fileObjs[id-1].Base64Data;
            
        }
        else
        {
            require(false,"file does not exist");
        }

        
    }

}