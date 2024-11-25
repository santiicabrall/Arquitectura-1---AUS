.macro leer_entero
li $v0,5
syscall
.end_macro

.macro imp_etiqueta (%label)
la $a0, %label
li $v0, 4
syscall
.end_macro

.macro terminado
li $v0,10
syscall
.end_macro	

.macro imp_error (%errno)
imp_etiqueta(error)
li $a0, %errno
li $v0, 1
syscall
imp_etiqueta(return)
.end_macro
		
.data

slist:	.word 0
cclist: .word 0
wclist: .word 0
schedv: .space 32
menu:	.ascii "Colecciones de objetos categorizados\n"
		.ascii "====================================\n"
		.ascii "1-Nueva categoria\n"
		.ascii "2-Siguiente categoria\n"                      #No anda
		.ascii "3-Categoria anterior\n"                       #No anda
		.ascii "4-Listar categorias\n"
		.ascii "5-Borrar categoria actual\n"
		.ascii "6-Anexar objeto a la categoria actual\n"
		.ascii "7-Listar objetos de la categoria\n"
		.ascii "8-Borrar objeto de la categoria\n"
		.ascii "0-Salir\n"
		.asciiz "Ingrese la opcion deseada: "
error:	.asciiz "Error: "
return:	.asciiz "\n"
catName:.asciiz "\nIngrese el nombre de una categoria: "
selCat:	.asciiz "\nSe ha seleccionado la categoria: "
idObj:	.asciiz "\nIngrese el ID del objeto a eliminar: "
objName:.asciiz "\nIngrese el nombre de un objeto: "
success:.asciiz "La operación se realizo con exito\n\n"
indicador: .asciiz " > "
separador: .asciiz " - "
objNoEncontrado: .asciiz "Not Found: Objeto no encontrado en la lista\n"
label201:	.asciiz "No hay categorias\n"
label202:	.asciiz "Existe una sola categoria\n"
label301:	.asciiz "No hay categorias para listar\n"
label401:	.asciiz "No hay categorias para eliminar\n"
label501:	.asciiz "No hay categoria para almacenar el objeto\n"
label601:	.asciiz "No hay categoria creada\n"
label602:	.asciiz "No hay objetos de la categoria para listar\n"
label701:	.asciiz "No existe categoria para eliminar objeto\n"
		.text
main:
	# initialization scheduler vector
	la $t0, schedv
	la $t1, newcategory
	sw $t1, 0($t0)
	la $t1, nextcategory
	sw $t1, 4($t0)
	la $t1, prevcategory
	sw $t1, 8($t0)
	la $t1, listcategories
	sw $t1, 12($t0)
	la $t1, delcategory
	sw $t1, 16($t0)
	la $t1, newobject
	sw $t1, 20($t0)
	la $t1, listobjects
	sw $t1, 24($t0)
	la $t1, delobject
	sw $t1, 28($t0)
	
main_loop:		#Bucle principal del programa, muestra el menú y maneja el programa segun la opcion elegida
    	                 

	jal menu_display
	beqz $v0, main_end
	addi $v0, $v0, -1		
	sll $v0, $v0, 2         
	la $t0, schedv 	
	add $t0, $t0, $v0 
	lw $t1, ($t0)	
    	la $ra, main_ret 		
    	jr $t1	
    					
main_ret:    #Punto de retorno a main_loop
    j main_loop		
main_end:	 #Finaliza el programa
	terminado

menu_display: #Muestra el menú de opciones, lee la opcion ingresada y verifica que sea valida
	
	imp_etiqueta(menu)
	leer_entero

	bgt $v0, 8, menu_display_L1
	bltz $v0, menu_display_L1

	jr $ra
	
menu_display_L1:  #Manejo de opciones inválidas
	imp_error(101)
	j menu_display
	
newcategory: #X
	addiu $sp, $sp, -4
	sw $ra, 4($sp)
	la $a0, catName		
	jal getblock
	move $a2, $v0	
	la $a0, cclist	
	li $a1, 0			
	jal addnode
	lw $t0, wclist
	bnez $t0, newcategory_end
	sw $v0, wclist	
newcategory_end: 
	li $v0, 0			
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra


listcategories:		#Enumera todas las categorías
	lw $t0, wclist
	lw $t1, cclist		
	beqz $t1, er301 		
	lw $t2, cclist
	j list_loop
list_loop:
	beq $t0, $t1, print_equal
	lw $a0, 8($t1)		
	li $v0, 4
	syscall 			
	lw $t1, 12($t1)	 	
	beq $t1, $t2, list_loop_end 
	j list_loop
print_equal:
	lw $t0, 8($t0) 		
	lw $t1, 12($t1)	 	

	la $a0, indicador 	
	li $v0, 4
	syscall
	la $a0, 0($t0) 		
	li $v0, 4
	syscall
	beq $t1, $t2, list_loop_end 
	j list_loop
list_loop_end:
	jr $ra
		
delcategory:  #Elimina la categoria en la que se encuentra
	
	
	addiu $sp, $sp, -4
	sw $ra, 4($sp)		
	lw $t0, wclist		
	beqz $t0, er401		
	lw $t0, 4($t0)		
	beqz $t0, del_empty_cat	
	lw $t1, wclist		
	la $a1, 4($t1)		
	jal loop_del_obj
	
	lw $ra, 4($sp)	
	addiu $sp, $sp, 4	
	jr $ra
	
loop_del_obj:   #Itera a través de todos los objetos de una categoría para eliminarlos
	lw $t2, 12($t0)		
	add $a0, $0, $t0		
	jal delnode		
	move $t0, $t2		
	beq $a0, $t0, del_empty_cat	
	j loop_del_obj
	
del_empty_cat:	#Elimina la categoría en la que se encunetra después de vaciar todos sus objetos

	lw $a0, wclist		
	la $a1, cclist		
	lw $t0, 12($a0)
	sw $t0, wclist		
	jal delnode		
	imp_etiqueta(success)
	
	lw $t1, cclist
	beqz $t1, reset_wclist	
	
	lw $ra, 4($sp)	
	addiu $sp, $sp, 4	
	jr $ra
	
reset_wclist:  #Resetea "wclist" cuando no quedan categorías
	sw $0, wclist		
	lw $ra, 4($sp)	
	addiu $sp, $sp, 4	
	jr $ra

newobject:  #Añade un objeto a la categoría en la que se encuentra
	
	addiu $sp, $sp, -4	
	sw $ra, 4($sp)
	lw $t0, wclist	
	beqz $t0, er501	
	
	la $a0, objName	
	jal getblock
	move $a2, $v0	
	lw $a0, wclist				
	la $a0, 4($a0) 
	lw $t0, 0($a0) 
	beqz $t0, insert_list	
				
	lw $t0, 0($t0)
	lw $t0, 4($t0) 
	add $a1, $t0, 1 
make_node:		#Crea un nuevo nodo para un elemento en la lista
	jal addnode		
	lw $t0, wclist		
	la $t0, 4($t0)	
	beqz $t0, first_node 
end_insert_node:		 #Finaliza la inserción de un nodo. Restaura el valor de retorno y limpia el stack antes de retornar al llamador
	li $v0, 0 
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra
insert_list:	 #Inicia la inserción de un nuevo nodo en la lista
	li $a1, 1 
	j make_node	
first_node:     #Inserta el primer nodo en la lista si la lista está vacía, asignando el valor dado y retornando a la subrutina para finalizar la inserción
	sw $v0, 0($t0) 
	j end_insert_node

listobjects:     #Itera en los objetos de una categoria
	lw $t0, wclist	
	beqz $t0, er601	
	lw $t0, 4($t0)	
	beqz $t0, er602	
	
	lw $t1, wclist	
	lw $t1, 4($t1)	
	
print_object:			#Lista los objetos de una categoria
	la $a0, 4($t1)		
	lw $a0, 0($a0)
	beq $a0, $a2, next	
	beqz $a0, print_object_end
	li $v0, 1
	syscall	
	la $a0, separador
	li $v0, 4
	syscall 
	la $a0, 8($t1)
	lw $a0, 0($a0)
	li $v0, 4
	syscall	
next:   #Continúa la iteración de los objetos luego de la verificacion
	la $t2, 12($t1)		
	lw $t2, 0($t2) 		
	beq $t2, $t0, print_object_end
	la $t1, 0($t2) 		
	j print_object
	
print_object_end:  #Fin de la impresión de objetos en la lista
	jr $ra

delobject:   #Elimina un objeto de una categoria
	addiu $sp, $sp, -4
	sw $ra, 4($sp)
	
	lw $t0, wclist		
	beqz $t0, er701		
	lw $t1, 4($t0)		
	beqz $t1, er701		
	imp_etiqueta(idObj)
	leer_entero	
	add $a2, $0, $v0		
	lw $t3, 4($t0)		
del_obj_loop:    #Bucle que recorre los objetos en la categoría para encontrar el objeto a eliminar

	lw $t2, 4($t1)		
	beqz $t2, not_found	
	beq $t2, $a2, found	
	lw $t1, 12($t1)		
	beq $t3, $t1, not_found	
				
	j del_obj_loop
found:			#Encuentra el objeto que se va a eliminar
	
	add $a0, $0, $t1		
	add $a1, $t0, 4		
	jal delnode
	imp_etiqueta(success)	
	
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra	
not_found:    #Imprime que el objeto no fue encontrado
	imp_etiqueta(objNoEncontrado)
	jr $ra


addnode: #X
	addi $sp, $sp, -8
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	jal smalloc
	sw $a1, 4($v0) 
	sw $a2, 8($v0)
	lw $a0, 4($sp)
	lw $t0, ($a0) 
	beqz $t0, addnode_empty_list
	
addnode_to_end: #X
	lw $t1, ($t0) 
	sw $t1, 0($v0)
	sw $t0, 12($v0)
	
	sw $v0, 12($t1)
	sw $v0, 0($t0)
	j addnode_exit
	
addnode_empty_list: #X
	sw $v0, ($a0)
	sw $v0, 0($v0)
	sw $v0, 12($v0)
	
addnode_exit: #X
	lw $ra, 8($sp)
	addi $sp, $sp, 8
	jr $ra


delnode: #X
	addi $sp, $sp, -8
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	lw $a0, 8($a0) 
	jal sfree 
	lw $a0, 4($sp) 
	lw $t0, 12($a0) 
	beq $a0, $t0, delnode_point_self
	lw $t1, 0($a0) 
	sw $t1, 0($t0)
	sw $t0, 12($t1)
	lw $t1, 0($a1) 
	bne $a0, $t1, delnode_exit
	sw $t0, ($a1) 
	j delnode_exit
delnode_point_self:#X
	sw $zero, ($a1) 
delnode_exit:#X
	jal sfree
	lw $ra, 8($sp)
	addi $sp, $sp, 8
	jr $ra


getblock:#X
	addi $sp, $sp, -4
	sw $ra, 4($sp)
	li $v0, 4
	syscall
	jal smalloc
	move $a0, $v0
	li $a1, 16
	li $v0, 8
	syscall
	move $v0, $a0
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra

smalloc: #X
	lw $t0, slist
	beqz $t0, sbrk
	move $v0, $t0
	lw $t0, 12($t0)
	sw $t0, slist
	jr $ra
sbrk: #X
	li $a0, 16 
	li $v0, 9
	syscall 
	jr $ra

sfree:	#X
	lw $t0, slist
	sw $t0, 12($a0)
	sw $a0, slist 
	jr $ra

er201:
	imp_error(201)
	imp_etiqueta(label201)
	jr $ra
er202:
	imp_error(202)
	imp_etiqueta(label202)
	jr $ra
er301:
	imp_error(301)
	imp_etiqueta(label301)
	jr $ra
er401:
	imp_error(401)
	imp_etiqueta(label401)
	jr $ra
er501:
	imp_error(501)
	imp_etiqueta(label501)
	jr $ra
er601:
	imp_error(601)
	imp_etiqueta(label601)
	jr $ra
er602:
	imp_error(602)
	imp_etiqueta(label602)
	jr $ra
er701:
	imp_error(701)
	imp_etiqueta(label701)
	jr $ra
