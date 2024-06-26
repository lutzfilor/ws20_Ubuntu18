# My 2nd program in R Programming
if (FALSE) {
    "This is a demo for multi-line comments and it should be put in single
     or double quotation marks"
}# End of multiline comment

myString <- "Hello, World!"
vec1  <- c('red','green',"yellow")						# vector
list1 <- list(c(2,5,3),21.3,sin)						# list
M = matrix( c('a','a','b','c','b','a'), nrow = 2, ncol = 3, byrow = TRUE)	# matrix
a <- array(c('green','yellow'),dim = c(3,3,2))					# array
apple_colors <- c('green','green','yellow','red','red','red','green')		# vector
factor_apple <- factor(apple_colors)						# factor
BMI <- 	data.frame(								# data frame
   gender = c("Male", "Male","Female"), 
   height = c(152, 171.5, 165), 
   weight = c(81,93, 78),
   Age = c(42,38,26)
)

print(class(myString))
print (myString)

print(class(vec1))
print(vec1)

print(class(list1))
print(list1)

print(class(a))
print(a)

print(class(M))
print(M)

print(class(apple_colors))
print(apple_colors)

print(class(factor_apple))
print(factor_apple)
print(nlevels(factor_apple))

print(class(BMI))
print(BMI)
