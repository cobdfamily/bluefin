import ApplicationServices

func getPid(from element: AXUIElement) -> pid_t? {
    var pid: pid_t = 0
    let result = AXUIElementGetPid(element, &pid)
    return result == .success ? pid : nil
}

// Function to get a specific attribute for a given AXUIElement
func getAttributeForUIElement(_ element: AXUIElement, withName attributeName: String) -> Any? {
    var value: AnyObject?
    let result = AXUIElementCopyAttributeValue(element, attributeName as CFString, &value)
    return result == .success ? value : nil
}

// Function to check if an AXUIElement is hidden
func isHidden(_ element: AXUIElement) -> Bool {
    var isHiddenValue: AnyObject?
    let result = AXUIElementCopyAttributeValue(element, kAXHiddenAttribute as CFString, &isHiddenValue)
    
    if result == .success, let isHidden = isHiddenValue as? Bool {
        return isHidden
    }
    return false
}

// Function to get children in navigation order for a given AXUIElement, filtering out hidden elements
func getChildrenInNavigationOrderForUIElement(_ element: AXUIElement) -> [AXUIElement] {
    var children: AnyObject?
    let result = AXUIElementCopyAttributeValue(element, "AXChildrenInNavigationOrder" as CFString, &children)
    
    if result == .success, let childrenArray = children as? [AXUIElement] {
        return childrenArray.filter { !isHidden($0) }
    }
    return []
}

// Function to get the parent of a given AXUIElement
func getParentForUIElement(_ element: AXUIElement) -> AXUIElement? {
    var parent: AnyObject?
    let result = AXUIElementCopyAttributeValue(element, kAXParentAttribute as CFString, &parent)
    
    return result == .success ? (parent as! AXUIElement) : nil
}

// Function to compare two AXUIElements by AXIdentifier, and if that fails, by AXPosition and size
func doElementsMatch(_ element1: AXUIElement, element2: AXUIElement) -> Bool {
if CFEqual( element1, element2 ) {
return true
}

    // First, try to match by AXIdentifier
    if let identifier1 = getAttributeForUIElement(element1, withName: kAXIdentifierAttribute as String),
       let identifier2 = getAttributeForUIElement(element2, withName: kAXIdentifierAttribute as String),
       identifier1 as? String == identifier2 as? String {
        return true
    }
    
    // If AXIdentifier does not match, try to match by AXPosition
    guard let position1 = getAttributeForUIElement(element1, withName: kAXPositionAttribute as String) as? CGPoint,
          let position2 = getAttributeForUIElement(element2, withName: kAXPositionAttribute as String) as? CGPoint,
          position1.x == position2.x || position1.y == position2.y else {
        return false
    }
    
    // If positions match, check if either the height or width of AXSize matches
    if let size1 = getAttributeForUIElement(element1, withName: kAXSizeAttribute as String) as? CGSize,
       let size2 = getAttributeForUIElement(element2, withName: kAXSizeAttribute as String) as? CGSize {
        return size1.height == size2.height || size1.width == size2.width
    }
    
    return false
}

// Function to get the index of an AXUIElement within its siblings using doElementsMatch
func getIndexInSiblingsForUIElement(_ element: AXUIElement) -> Int? {
    guard let parent = getParentForUIElement(element) else {
        return nil
    }
    let siblings = getChildrenInNavigationOrderForUIElement(parent)
    
    return siblings.firstIndex(where: { doElementsMatch($0, element2: element) })
}

// Function to get the index of an AXUIElement within its siblings that share a role property using doElementsMatch
func getIndexInSiblingsForUIElement(_ element: AXUIElement, withRole roleName: String ) -> Int? {
    guard let parent = getParentForUIElement(element) else {
        return nil
    }
    let siblings = getChildrenInNavigationOrderForUIElement(parent).filter { getAttributeForUIElement( $0, withName: "AXRole" ) as! String == roleName }
    
    return siblings.firstIndex(where: { doElementsMatch($0, element2: element) })
}

// Function to get the path to an AXUIElement by moving up the hierarchy
func getPathToUIElement(_ element: AXUIElement) -> [String] {
    var path: [String] = []
    var currentElement: AXUIElement? = element

if isHidden( element ) {
return [];
}

    while let reviewedElement = currentElement {
        if let roleName = getAttributeForUIElement( reviewedElement, withName: "AXRole" ) as? String, let indexInSiblings = getIndexInSiblingsForUIElement(reviewedElement, withRole: roleName) {
            path.insert("\(roleName)#\(indexInSiblings)", at: 0) // Insert at the beginning to build the path from top-down
        

        // Move to the parent element
        currentElement = getParentForUIElement(reviewedElement)
} else {
currentElement = nil
}


    }
    
    return path
}
