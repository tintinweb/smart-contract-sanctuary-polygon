// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

//contract to record all crowdfunding projects
contract CreateBlogs {
    address[] public publishedBlogs;

    event ProjectCreated(
        string title,
        string description,
        string[] categories,
        string mainImage,
        string slug,
        string author,
        address indexed ownerWallet,
        address blogAddress,
        uint256 indexed timestamp
    );

    function totalPublishedProjs() public view returns (uint256) {
        return publishedBlogs.length;
    }

    function createBlog(
        string memory blogTitle,
        string memory blogDescription,
        string[] memory blogCategories,
        string memory blogMainImage,
        string memory blogSlug,
        string memory blogAuthor
    ) public {
        //initializing FundProject contract
        FetchBlogs newproj = new FetchBlogs(
            //passing arguments from constructor function
            blogTitle,
            blogDescription,
            blogCategories,
            blogMainImage,
            blogSlug,
            blogAuthor
        );

        //pushing project address
        publishedBlogs.push(address(newproj));

        //calling ProjectCreated (event above)
        emit ProjectCreated(
            blogTitle,
            blogDescription,
            blogCategories,
            blogMainImage,
            blogSlug,
            blogAuthor,
            msg.sender,
            address(newproj),
            block.timestamp
        );
    }
}

contract FetchBlogs {
    //defining state variables
    string public title;
    string public description;
    string[] public categories;
    string public mainImage;
    string public slug;
    string public author;
    address ownerWallet; //address where amount to be transfered

    constructor(
        string memory blogTitle,
        string memory blogDescription,
        string[] memory blogCategories,
        string memory blogMainImage,
        string memory blogSlug,
        string memory blogAuthor
    ) {
        //mapping values
        title = blogTitle;
        description = blogDescription;
        categories = blogCategories;
        mainImage = blogMainImage;
        slug = blogSlug;
        author = blogAuthor;
    }
}