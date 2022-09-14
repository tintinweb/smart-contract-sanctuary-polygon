// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "Strings.sol";
import "Base64.sol";

// values are string because they can be numbers or percents
struct Box {
    string x;
    string y;
    string width;
    string height;
}

// values are string because they can be numbers or percents
struct Point {
    string x;
    string y;
}

/**
 * @dev generates nft metadata onchain with an SVG image.
 * @dev use it like this:
 * <pre>
    string memory tokenURI = svg.svgElementToTokenURI(
        svg.svgToImageURI(
            svg.buildSVGElement(
                1080,
                1080,
                "white",
                strings.concat(
                    svg.rect(
                        Box("48", "48", "984", "984"),
                        svg.prop(
                            "style", 
                            strings.concat(
                                svg.style("fill", "#fff0e6"),
                                svg.prop("stroke", "black"),
                                svg.prop("stroke-width", "3")
                            )
                        )
                    ),
                    svg.text(
                        string.concat(
                            svg.prop("x", "50%"),
                            svg.prop("y", "50%"),
                            svg.prop("dominant-baseline", "middle"),
                            svg.prop("text-anchor", "middle"),
                            svg.prop(
                                "style", 
                                strings.concat(
                                    svg.style("fill", "#fff0e6"),
                                    svg.prop("font-size", "120px"),
                                    svg.prop("font-family", "Comic Sans MS,Comic Sans,cursive")
                                )
                            )
                        ),
                        "You're Awesome!"
                    )
                )
            )
        ),
        "Onchain NFT #1234",
        "#Super dope NFT"
    );
 * </pre>
 * @dev uses a little code from https://github.com/PatrickAlphaC/all-on-chain-generated-nft/blob/main/contracts/RandomSVG.sol
 * @dev and a lot of code from https://github.com/w1nt3r-eth/hot-chain-svg/blob/main/contracts/SVG.sol
 */
library svg {
    using Strings for string;

    /**
     * @dev builds a token uri for an image. You can paste the result in your
     *     browser and it will show a JSON document.
     * @param imageURI the link to the image. See `svgToImageURI(string)`
     * @param tokenName the name attribute for the token metadata
     * @param externalURL the name attribute for the token metadata
     * @param tokenDescription the description attribute. This can contain
     *     markdown formatting.
     */
    function svgElementToTokenURI(
        string memory imageURI,
        string memory tokenName,
        string memory externalURL,
        string memory tokenDescription
    ) public pure returns (string memory) {
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        string.concat(
                            '{"name":"',
                            tokenName,
                            '","description":"',
                            tokenDescription,
                            '","external_url":"',
                            externalURL,
                            '","attributes":"","image":"',
                            imageURI,
                            '"}'
                        )
                    )
                )
            );
    }

    /**
     * @dev builds a image uri for an SVG element. You can paste the result in
     *     your browser and it will show an SVG image.
     * @param svgElement the <svg ...>...</svg> document.
     */
    function svgToImageURI(string memory svgElement)
        public
        pure
        returns (string memory)
    {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svgElement)))
        );
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    /* STRUCTURE ELEMENTS */

    /**
     * @dev builds an <svg> element
     * @dev see https://www.w3.org/TR/SVG11/struct.html#NewDocument
     * @param props additional SVG element props
     * - width=the width of the element; 100% if not specified
     * - height=the height of the element; 100% if not specified
     * - x=for embedded SVG, the x position of the upper left corner
     * - y=for embedded SVG, the y position of the upper left corner
     * - preserveAspectRatio=default is 'xMidYMid meet', see
     *      https://www.w3.org/TR/SVG11/coords.html#PreserveAspectRatioAttribute
     * - zoomAndPan=either 'disable' or 'magnify'
     * @param children a concatenated string containing the inner elements.
     */
    function svgDocument(string memory props, string memory children)
        public
        pure
        returns (string memory)
    {
        return
            el(
                "svg",
                string.concat(
                    prop("xmlns", "http://www.w3.org/2000/svg"),
                    prop("xmlns:xlink", "http://www.w3.org/1999/xlink"),
                    prop("version", "1.1"),
                    props
                ),
                children
            );
    }

    /**
     * @dev builds an SVG group.
     * @dev see https://www.w3.org/TR/SVG11/struct.html#Groups
     * @param props the group properties.
     * - id=group name
     * - fill=group fill color
     * - opacity=group opacity
     * @param children a concatenated string containing the inner elements.
     */
    function g(string memory props, string memory children)
        public
        pure
        returns (string memory)
    {
        return el("g", props, children);
    }

    /**
     * @dev builds a defs element to contain referencable elements
     * @dev Child elements should have an "id" property with a unique value.
     * @dev An element with id="foo" can be referenced as "url(#foo)".
     * @dev see https://www.w3.org/TR/SVG11/struct.html#DefsElement
     * @param children a concatenated string containing the child elements.
     */
    function defs(string memory children) public pure returns (string memory) {
        return string.concat("<defs>", children, "</defs>");
    }

    /**
     * @dev builds a defs element to contain referencable elements
     * @dev Child elements should have an "id" property with a unique value.
     * @dev An element with id="foo" can be referenced as "url(#foo)".
     * @dev see https://www.w3.org/TR/SVG11/struct.html#DefsElement
     * @param props any properties
     * @param children a concatenated string containing the child elements.
     */
    function defs(string memory props, string memory children)
        public
        pure
        returns (string memory)
    {
        return el("defs", props, children);
    }

    /* SHAPES */
    /* https://www.w3.org/TR/SVG11/shapes.html */

    /**
     * @dev builds a line element
     * @dev see https://www.w3.org/TR/SVG11/shapes.html#LineElement
     * @param p1 the start of the line
     * @param p2 the end of the line
     * @param props additional line properties
     */
    function line(
        Point memory p1,
        Point memory p2,
        string memory props
    ) public pure returns (string memory) {
        return el("line", _lineProps(p1, p2, props));
    }

    /**
     * @dev builds a line element with children
     * @dev see https://www.w3.org/TR/SVG11/shapes.html#LineElement
     * @param p1 the start of the line
     * @param p2 the end of the line
     * @param props additional line properties
     * @param children a concatenated string containing any inner animation or
     *     descriptive elements
     */
    function line(
        Point memory p1,
        Point memory p2,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("line", _lineProps(p1, p2, props), children);
    }

    function _lineProps(
        Point memory p1,
        Point memory p2,
        string memory props
    ) internal pure returns (string memory) {
        return
            string.concat(
                prop("x1", p1.x),
                prop("y1", p1.y),
                prop("x2", p2.x),
                prop("y2", p2.y),
                props
            );
    }

    /**
     * @dev builds a circle element
     * @dev see https://www.w3.org/TR/SVG11/shapes.html#CircleElement
     * @param center the circle center point
     * @param radius the circle radius (number or %)
     * @param props additional circle properties
     */
    function circle(
        Point memory center,
        string memory radius,
        string memory props
    ) public pure returns (string memory) {
        return el("circle", _circleProps(center, radius, props));
    }

    /**
     * @dev builds a circle element with children
     * @dev see https://www.w3.org/TR/SVG11/shapes.html#CircleElement
     * @param center the circle center point
     * @param radius the circle radius (number or %)
     * @param props additional circle properties
     * @param children a concatenated string containing any inner animation or
     *     descriptive elements
     */
    function circle(
        Point memory center,
        string memory radius,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("circle", _circleProps(center, radius, props), children);
    }

    function _circleProps(
        Point memory center,
        string memory radius,
        string memory props
    ) internal pure returns (string memory) {
        return
            string.concat(
                prop("cx", center.x),
                prop("cy", center.y),
                prop("r", radius),
                props
            );
    }

    /**
     * @dev builds an ellipse element
     * @dev see https://www.w3.org/TR/SVG11/shapes.html#EllipseElement
     * @param center the ellipse center point
     * @param rx the x-axis radius (number or %)
     * @param ry the y-axis radius (number or %)
     * @param props additional ellipse properties
     */
    function ellipse(
        Point memory center,
        string memory rx,
        string memory ry,
        string memory props
    ) public pure returns (string memory) {
        return el("ellipse", _ellipseProps(center, rx, ry, props));
    }

    /**
     * @dev builds an ellipse element with children
     * @dev see https://www.w3.org/TR/SVG11/shapes.html#EllipseElement
     * @param center the ellipse center point
     * @param rx the x-axis radius (number or %)
     * @param ry the y-axis radius (number or %)
     * @param props additional ellipse properties
     * @param children a concatenated string containing any inner animation or
     *     descriptive elements
     */
    function ellipse(
        Point memory center,
        string memory rx,
        string memory ry,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("ellipse", _ellipseProps(center, rx, ry, props), children);
    }

    function _ellipseProps(
        Point memory center,
        string memory rx,
        string memory ry,
        string memory props
    ) internal pure returns (string memory) {
        return
            string.concat(
                prop("cx", center.x),
                prop("cy", center.y),
                prop("rx", rx),
                prop("ry", ry),
                props
            );
    }

    /**
     * @dev builds a rectangle element
     * @dev see https://www.w3.org/TR/SVG11/shapes.html#RectElement
     * @param bounds the rectangle dimensions
     * @param props additional rectangle properties.
     */
    function rect(Box memory bounds, string memory props)
        public
        pure
        returns (string memory)
    {
        return el("rect", _rectProps(bounds, props));
    }

    /**
     * @dev builds a rectangle element with children
     * @dev see https://www.w3.org/TR/SVG11/shapes.html#RectElement
     * @param bounds the rectangle dimensions
     * @param props additional rectangle properties.
     * @param children a concatenated string containing any inner animation or
     *     descriptive elements
     */
    function rect(
        Box memory bounds,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("rect", _rectProps(bounds, props), children);
    }

    function _rectProps(Box memory bounds, string memory props)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                prop("x", bounds.x),
                prop("y", bounds.y),
                prop("width", bounds.width),
                prop("height", bounds.height),
                props
            );
    }

    /**
     * @dev build a path element.
     * @dev a path is an outline of a shape that can be filled, stroked, or
     *     used as a clipping path.
     * @dev see https://www.w3.org/TR/SVG11/paths.html
     * @param pathData a space-delimited list of path commands
     * @param props additional path properties
     * - pathLength=Scale the path to fit this length
     */
    function path(string memory pathData, string memory props)
        public
        pure
        returns (string memory)
    {
        return el("path", _pathProps(pathData, props));
    }

    /**
     * @dev build a path element with children.
     * @dev a path is an outline of a shape that can be filled, stroked, or
     *     used as a clipping path.
     * @dev see https://www.w3.org/TR/SVG11/paths.html
     * @param pathData a space-delimited list of path commands
     * @param props additional path properties
     * - pathLength=Scale the path to fit this length
     * @param children a concatenated string containing any inner animation or
     *     descriptive elements
     */
    function path(
        string memory pathData,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("path", _pathProps(pathData, props), children);
    }

    function _pathProps(string memory pathData, string memory props)
        internal
        pure
        returns (string memory)
    {
        return string.concat(prop("d", pathData), props);
    }

    /**
     * @dev builds a polyline element
     * @dev A polyline is a special case of path, with a moveto operation to
     *    the first cooridinate pair, and lineto operations to each subsequent
     *    coordinate pair.
     * @dev https://www.w3.org/TR/SVG11/shapes.html#PolylineElement
     * @param points a space-delimited list of points
     * @param props additional polyline properties.
     */
    function polyline(string memory points, string memory props)
        public
        pure
        returns (string memory)
    {
        return el("polyline", _polylineProps(points, props));
    }

    /**
     * @dev builds a polyline element with children
     * @dev A polyline is a special case of path, with a moveto operation to
     *    the first cooridinate pair, and lineto operations to each subsequent
     *    coordinate pair.
     * @dev https://www.w3.org/TR/SVG11/shapes.html#PolylineElement
     * @param points a space-delimited list of points
     * @param props additional polyline properties.
     * @param children a concatenated string containing any inner animation or
     *     descriptive elements
     */
    function polyline(
        string memory points,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("polyline", _polylineProps(points, props), children);
    }

    /**
     * @dev builds a polygon element
     * @dev A polygon is a special case of path, with a moveto operation to
     *    the first cooridinate pair, lineto operations to each subsequent
     *    coordinate pair, followed by a closepath command.
     * @dev https://www.w3.org/TR/SVG11/shapes.html#PolygonElement
     * @param points a space-delimited list of points
     * @param props additional polygon properties.
     */
    function polygon(string memory points, string memory props)
        public
        pure
        returns (string memory)
    {
        return el("polygon", _polylineProps(points, props));
    }

    /**
     * @dev builds a polygon element with children
     * @dev A polygon is a special case of path, with a moveto operation to
     *    the first cooridinate pair, lineto operations to each subsequent
     *    coordinate pair, followed by a closepath command.
     * @dev https://www.w3.org/TR/SVG11/shapes.html#PolygonElement
     * @param points a space-delimited list of points
     * @param props additional polygon properties.
     * @param children a concatenated string containing any inner animation or
     *     descriptive elements
     */
    function polygon(
        string memory points,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("polygon", _polylineProps(points, props), children);
    }

    function _polylineProps(string memory points, string memory props)
        internal
        pure
        returns (string memory)
    {
        return string.concat(prop("points", points), props);
    }

    /* TEXT */
    /* see https://www.w3.org/TR/SVG11/text.html */

    /**
     * @dev builds a text element
     * @dev see https://www.w3.org/TR/SVG11/text.html#TextElement
     * @param props the text element properties
     * - x=a single number or % for the x-axis location of the first letter, or
     *     a list to set the horizontal position of each letter
     * - y=a single number or % for the y-axis location of the first letter, or
     *     a list to set the vertical position of each letter
     * - dx=horizontal spacing between letters if not specified in x
     * - dy=vertical spacing between letters if not specified in y
     * - rotate=a list of rotations
     * - textLength=a target length for the text
     * - lengthAdjust=either 'spacing' or 'spacingAndGlyphs'; what to adjust to
     *     reach the target length.
     * @param children the text, a CDATA element, or a concatenated string
     *      containing tspan elements, animation, or descriptive elements
     */
    function text(string memory props, string memory children)
        public
        pure
        returns (string memory)
    {
        return el("text", props, children);
    }

    /**
     * @dev build a tspan element, embeddable in text or parent tspan elements
     * @dev see https://www.w3.org/TR/SVG11/text.html#TSpanElement
     * @param props see `text`
     * @param children see `text`
     */
    function tspan(string memory props, string memory children)
        public
        pure
        returns (string memory)
    {
        return el("tspan", props, children);
    }

    /**
     * @dev builds a tref element
     * @dev see https://www.w3.org/TR/SVG11/text.html#TRefElement
     * @param link a reference to a previously defined text element
     * @param props additional text properties
     */
    function tref(string memory link, string memory props)
        public
        pure
        returns (string memory)
    {
        return el("tref", _trefProps(link, props));
    }

    /**
     * @dev builds a tref element with children
     * @dev see https://www.w3.org/TR/SVG11/text.html#TRefElement
     * @param link a reference to a previously defined text element
     * @param props additional text properties
     * @param children a concatenated string containing any inner animation or
     *     descriptive elements
     */
    function tref(
        string memory link,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("tref", _trefProps(link, props), children);
    }

    function _trefProps(string memory link, string memory props)
        internal
        pure
        returns (string memory)
    {
        return string.concat(prop("link", link), props);
    }

    /**
     * @dev builds a CDATA element
     * @param content the text
     */
    function cdata(string memory content) public pure returns (string memory) {
        return string.concat("<![CDATA[", content, "]]>");
    }

    /* FILTERS, GRADIENTS, and PATTERNS */

    /**
     * @dev defines a filter element
     * @dev use `el(primitiveName, props)` to build the primitives.
     * @dev see https://www.w3.org/TR/SVG11/filters.html for primitive attributes.
     * @param id the unique id to reference the filter
     * @param props the properties for the filter
     * - filterUnits=either "userSpaceOnUse" or "objectBoundingBox"; how to
     *     determine the vector point positions. Default is "objectBoundingBox".
     * - x=horizontal start point of the filter clipping region. Default is -10%.
     * - y=vertical start point of the filter clipping region. Default is -10%.
     * - width=horizontal length of the filter clipping region. Default is 120%.
     * - height=vertical length of the filter clipping region. Default is 120%.
     * - xlink:href=reference to another filter to inherit attributes
     * @param children a concatenated string containing the filter primitives.
     */
    function filter(
        string memory id,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("filter", string.concat(prop("id", id), props), children);
    }

    /**
     * @dev builds a radial gradient
     * @dev this MUST occur within a <defs> element.
     * @dev see https://www.w3.org/TR/SVG11/pservers.html#LinearGradients
     * @param id the unique id to reference the gradient
     * @param props the properties for the gradient
     * - gradientUnits=either "userSpaceOnUse" or "objectBoundingBox"; how to
     *     determine the vector point positions. Default is "objectBoundingBox".
     * - gradientTransform=transformation to apply
     * - cx=horizontal center of gradient. Default is "50%"
     * - cy=vertical center of gradient. Default is "50%"
     * - fx=horizontal focus of gradient. Default is "0%"
     * - fy=vertical focus of gradient. Default is "0%"
     * - spreadMethod="pad", "reflect", or "repeat"
     * - href=reference to another gradient, to inherit values and stops
     * @param children a concatenated string containing <stop> elements.
     */
    function radialGradient(
        string memory id,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return
            el(
                "radialGradient",
                string.concat(prop("id", id), props),
                children
            );
    }

    /**
     * @dev builds a linear gradient
     * @dev this MUST occur within a <defs> element.
     * @dev see https://www.w3.org/TR/SVG11/pservers.html#RadialGradients
     * @param id the unique id to reference the gradient
     * @param props the properties for the gradient
     * - gradientUnits=either "userSpaceOnUse" or "objectBoundingBox"; how to
     *     determine the vector point positions. Default is "objectBoundingBox".
     * - gradientTransform=transformation to apply
     * - x1=horizontal start point. Default is 0%.
     * - y1=vertical start point. Default is 0%.
     * - x2=horizontal end point. Default is 100%.
     * - y2=vertical end point. Default is 100%.
     * - spreadMethod="pad", "reflect", or "repeat"
     * - href=reference to another gradient, to inherit values and stops
     * @param children a concatenated string containing <stop> elements.
     */
    function linearGradient(
        string memory id,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return
            el(
                "linearGradient",
                string.concat(prop("id", id), props),
                children
            );
    }

    /**
     * @dev builds a stop for a gradient
     * @dev Your gradient needs stops at offsets 0% and 100%.
     * @dev You can put more stops in between to make a fancy gradient.
     * @dev see https://www.w3.org/TR/SVG11/pservers.html#GradientStops
     * @param offset the offset for the stop, 0% to 100%
     * @param stopColor the color of the stop
     * @param props additional properties
     * - stop-opacity=the opacity, 0.0-1.0
     */
    function gradientStop(
        uint256 offset,
        string memory stopColor,
        string memory props
    ) public pure returns (string memory) {
        return
            el(
                "stop",
                string.concat(
                    prop("stop-color", stopColor),
                    " ",
                    prop(
                        "offset",
                        string.concat(Strings.toString(offset), "%")
                    ),
                    " ",
                    props
                )
            );
    }

    /**
     * @dev builds a pattern
     * @dev this should go in a <defs> element and be referenced in a fill
     *     attribute.
     * @dev see https://www.w3.org/TR/SVG11/pservers.html#Patterns
     * @param id the unique id to reference the pattern
     * - patternUnits='userSpaceOnUse' or 'objectBoundingBox', defines the
     *     coordinate space for the bounding box surrounding the pattern
     *     contents. Default is 'objectBoundingBox'.
     * - patternContentUnits=''userSpaceOnUse' or 'objectBoundingBox', defines
     *     the coordinate space for the elements in the pattern content.
     *     Default is 'userSpaceOnUse'.
     * - patternTransform=additional transformations to apply, used for skewing
     *     etc. Default is no transformation (identity matrix).
     * - x=upper left corner of the pattern bounding box
     * - y=upper left corner of the pattern bounding box
     * - width=bounding box width
     * - height=bounding box height
     * - link=reference to another pattern to inherit attributes. If this
     *     pattern has no children, it will inherit children from the
     *     refrerenced pattern.
     * - preserveAspectRatio=default is 'xMidYMid meet', see
     *      https://www.w3.org/TR/SVG11/coords.html#PreserveAspectRatioAttribute
     * @param props the properties for the pattern
     * @param children a concatenated string the elements that make the pattern
     */
    function pattern(
        string memory id,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("pattern", string.concat(prop("id", id), props), children);
    }

    /**
     * @dev builds an <image> element.
     * @dev see https://www.w3.org/TR/SVG11/struct.html#ImageElement
     * @param href the path to the image, either PNG, JPEG, or 'image/svg+xml'
     * @param bounds the image dimensions
     * @param props additional image properties.
     */
    function image(
        string memory href,
        Box memory bounds,
        string memory props
    ) public pure returns (string memory) {
        return el("image", _imageProps(href, bounds, props));
    }

    /**
     * @dev builds an <image> element.
     * @dev see https://www.w3.org/TR/SVG11/struct.html#ImageElement
     * @param href the path to the image, either PNG, JPEG, or 'image/svg+xml'
     * @param bounds the image dimensions
     * @param props additional image properties.
     * @param children any children
     */
    function image(
        string memory href,
        Box memory bounds,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("image", _imageProps(href, bounds, props), children);
    }

    function _imageProps(
        string memory href,
        Box memory bounds,
        string memory props
    ) internal pure returns (string memory) {
        return
            string.concat(
                prop("xlink:href", href),
                prop("x", bounds.x),
                prop("y", bounds.y),
                prop("width", bounds.width),
                prop("height", bounds.height),
                props
            );
    }

    /* COMMON */
    /**
     * @dev build any SVG element (or html or xml) with children
     * @param tag the element type
     * @param props the element attributes
     * @param children the concatenated inner elements
     */
    function el(
        string memory tag,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return
            string.concat("<", tag, " ", props, ">", children, "</", tag, ">");
    }

    /**
     * @dev build any SVG element (or html or xml) without children
     * @param tag the element type
     * @param props the element attributes
     */
    function el(string memory tag, string memory props)
        public
        pure
        returns (string memory)
    {
        return string.concat("<", tag, " ", props, "/>");
    }

    /**
     * @dev build an element attribute, `key`="`val`"
     * @param key the attribute name
     * @param val the attribute value
     */
    function prop(string memory key, string memory val)
        public
        pure
        returns (string memory)
    {
        return string.concat(key, "=", '"', val, '" ');
    }

    /**
     * @dev build a <style> element.
     * @dev This should be inside a <defs> element.
     * @param css the entire cascading style sheet.
     */
    function styleSheet(string memory css) public pure returns (string memory) {
        return el("style", 'type="text/css"', cdata(css));
    }

    /**
     * @dev builds a css style rule
     * @param selector the css selector
     * @param styles the styles for the selector (i.e. everything inside the
     *     curly brackets)
     */
    function cssRule(string memory selector, string memory styles)
        public
        pure
        returns (string memory)
    {
        return string.concat(selector, " {", styles, "}\n");
    }

    /**
     * @dev build a css style element, `key`:`val`;
     * @dev can be used for an inline style attribute or in a style sheet.
     * @param key the style element name
     * @param val the style value
     */
    function style(string memory key, string memory val)
        public
        pure
        returns (string memory)
    {
        return string.concat(key, ":", val, ";");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @title Base64
 * @author Brecht Devos - <[email protected]>
 * @notice Provides functions for encoding/decoding base64
 */
library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(
                            18,
                            and(
                                mload(add(tablePtr, and(shr(24, input), 0xFF))),
                                0xFF
                            )
                        ),
                        shl(
                            12,
                            and(
                                mload(add(tablePtr, and(shr(16, input), 0xFF))),
                                0xFF
                            )
                        )
                    ),
                    add(
                        shl(
                            6,
                            and(
                                mload(add(tablePtr, and(shr(8, input), 0xFF))),
                                0xFF
                            )
                        ),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}