/**
 * Include this script in your HTML to use JSX compiled code without React
 */
const React = {
    /**
     * Main function called by your code after JSX compilation
     * 
     * @param {string} tag HTML tag
     * @param {Object} attrs HTML attributes to add to the element ("on" attributes are added as listeners)
     * @param  {...HTMLElement|...string|...array[HTMLElement|string]} children
     * 
     * @returns {HTMLElement}
     */
    createElement: function (tag, attrs, ...children) {
        const element = document.createElement(tag);

        for (const name in attrs) {
            if (Object.prototype.hasOwnProperty.call(attrs, name)) {
                const value = attrs[name];
                
                if (value !== false && value !== null) {
                    if (name.startsWith("on") && typeof value === "function") {
                        element.addEventListener(name.substring(2), value);
                    }
                    else {
                        element.setAttribute(name, value.toString());
                    }
                }
            }
        }

        for (const child of children) {
            React._appendChild(element, child);
        }

        return element;
    },

    /**
     * Private function; append a child to a parent accordingly to his type
     * 
     * @param {HTMLElement} parent
     * @param {HTMLElement|string|array[HTMLElement|string]} child
     */
    _appendChild: function(parent, child) {
        if (Array.isArray(child)) {
            child.map((c) => React._appendChild(parent, c));
        }
        else if (child.nodeType) {
            parent.appendChild(child);
        }
        else {
            parent.appendChild(document.createTextNode(child.toString()));
        }
    }
};