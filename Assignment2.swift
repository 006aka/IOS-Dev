import Playgrounds

#Playground {
   let fruits = ["Apple", "Banana", "Orange", "Mango", "Grapes"]
    print(fruits[2])
}
#Playground {
    var numbers: Set<Int> = [10, 20, 30, 40]
    numbers.insert(50)
    print(numbers)
}
#Playground {
    let languages = [
        "Python": 1991,
        "Java": 1995,
        "Swift": 2014
    ]
    print(languages["Swift"]!)
}
#Playground {
    var colors = ["Red", "Blue", "Green", "Yellow"]
    colors[1] = "Purple"
    print(colors)
}
#Playground {
    let set1: Set<Int> = [1, 2, 3, 4]
    let set2: Set<Int> = [3, 4, 5, 6]
    let result = set1.intersection(set2)
    print(result)
}
#Playground {
    var students = [
        "Alex": 80,
        "John": 90,
        "Mike": 75
    ]
    students["Alex"] = 95
    print(students)
}
#Playground {
    var fruits1 = ["apple", "banana"]
    let fruits2 = ["cherry", "date"]
    fruits1.append(contentsOf: fruits2)
    print(fruits1)
}
#Playground {
    var countries = [
        "Kazakhstan": 19000000,
        "USA": 331000000,
        "Japan": 125000000,
    ]
    countries["Germany"] = 84000000
}
#Playground {
    let animals1: Set<String> = ["cat", "dog"]
    let animals2: Set<String> = ["dog", "mouse"]
    let unionSet = animals1.union(animals2)
    let finalSet = unionSet.subtracting(animals2)
    print(finalSet)
}
#Playground {
    let grades = [
        "Alex": [85, 90, 78],
        "John": [88, 92, 95],
        "Mike": [70, 75, 80]
    ]
    print(grades["John"]![1])
}
