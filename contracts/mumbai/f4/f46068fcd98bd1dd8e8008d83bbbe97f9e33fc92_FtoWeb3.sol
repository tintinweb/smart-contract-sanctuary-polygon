/**
 *Submitted for verification at polygonscan.com on 2022-08-22
*/

pragma solidity 0.8.7;


contract FtoWeb3
{

    function char(bytes1 b) internal pure returns (bytes1 c)
    {
        if (uint8(b) < 10)
            return bytes1(uint8(b) + 0x30);
        else
            return bytes1(uint8(b) + 0x57);
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

        uint FileSize;

        bool Completed;

        string Id;

        uint BlockSize;
    }

    int public versions=9;

    address payable public owner;
    FileObj[] fileObjs;

    constructor() payable
    {
        owner = payable(msg.sender);
    }



    function FileExist(string memory id) public view returns (bool)
    {
        bool IsFileExist = false;
        for (uint i=0;fileObjs.length>i;i++)
        {

            if( keccak256(abi.encodePacked(fileObjs[i].Id))==keccak256(abi.encodePacked(id)))
            {
                IsFileExist=true;
            }
        }

        return IsFileExist;
    }

    function GetNumberId(string memory id) private view returns (uint)
    {

        for (uint i=0;fileObjs.length>i;i++)
        {

            if(keccak256(abi.encodePacked(fileObjs[i].Id))==keccak256(abi.encodePacked(id)))
            {
                return i;
            }
        }


    }

    function CreateFile(string memory id,string memory fileName,uint BlockSize) public payable
    {

        if(FileExist(id))
        {
            require(false,"File exists");
        }
        else
        {
            address owner = payable(msg.sender);


            FileObj memory newFileObj = FileObj(owner,"",fileName,0,false,id,BlockSize);

            fileObjs.push(newFileObj);
        }


    }


    function AddFile(string memory id,string memory base64Data,uint partId) public payable
    {


        bool IsFileExist = FileExist(id);
        uint NumberId = GetNumberId(id);

        if(IsFileExist)
        {
            address owner = payable(msg.sender);



            if(fileObjs[NumberId].Owner==owner)
            {
                if(fileObjs[NumberId].FileSize==partId-1)
                {
                    fileObjs[NumberId].FileSize++;
                    fileObjs[NumberId].Base64Data=string(abi.encodePacked(fileObjs[NumberId].Base64Data,base64Data));
                }
                else
                {
                    require(false,"Sequence is broken");
                }


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

    function getFile(string memory id) public view returns(string memory)
    {
        bool IsFileExist=FileExist(id);
        uint numberId=GetNumberId(id);

        if(IsFileExist)
        {
            return fileObjs[numberId].Base64Data;
        }
        else
        {
            require(false,"file does not exist");
        }


    }

    function getFileSize(string memory id) public view returns(uint)
    {
        bool IsFileExist=FileExist(id);
        uint numberId=GetNumberId(id);

        if(IsFileExist)
        {
            return fileObjs[numberId].FileSize;
        }
        else
        {
            require(false,"file does not exist");
        }

    }

    function getFileName(string memory id) public view returns(string memory)
    {
        bool IsFileExist=FileExist(id);
        uint numberId=GetNumberId(id);

        if(IsFileExist)
        {
            return fileObjs[numberId].FileName;
        }
        else
        {
            require(false,"file does not exist");
        }

    }


    function getBlockSize(string memory id) public view returns(uint)
    {
        bool IsFileExist=FileExist(id);
        uint numberId=GetNumberId(id);

        if(IsFileExist)
        {
            return fileObjs[numberId].BlockSize;
        }
        else
        {
            require(false,"file does not exist");
        }

    }
}