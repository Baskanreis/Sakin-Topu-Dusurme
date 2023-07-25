; 14/07/2023 başlama
; 25/07/2023 bitirme
; Telif Hakları Saklıdır ©
;  ____    _    ____  _  __    _    _   _  ™
; | __ )  / \  / ___|| |/ /   / \  | \ | |  
; |  _ \ / _ \ \___ \| ' /   / _ \ |  \| |
; | |_) / ___ \ ___) | . \  / ___ \| |\  |
; |____/_/   \_\____/|_|\_\/_/   \_\_| \_|
;                )__)                    
org 0x7C00
%define GENISLIK 320
%define YUKSEKLİK 200
%define SUTUN 40
%define HIZA 25

%define SIYAH 0
%define MAVI 1
%define YESIL 2
%define CYAN 3
%define KIRMIZI 4
%define EFLATUN 5
%define KAHVERENGI 6
%define ACIKGRI 7
%define KOYUGRI 8
%define ACIKMAVI 9
%define ACIKYESIL 10
%define ACIKCYAN 11
%define ACIKKIRMIZI 12
%define ACIKEFLATUN 13
%define SARI 14
%define BEYAZ 15

%define ARKA_PLAN_RENGI SIYAH

%define TOP_GENISLIGI 16
%define TOP_YUKSEKLIGI 16
%define TOP_HIZI 6
%define TOP_RENGI SARI

%define CUBUK_UZUNLUGU 50
%define CUBUK_YUKSEKLIGI 3
%define CUBUK_RENGI YESIL
%define CUBUK_HIZI 10

%define VGA 0xA000

%define PUAN_HANE_SAYISI 5

struc oyun
  .surerlilik: resb 1
  .top_x: resw 1
  .top_y: resw 1
  .top_dx: resw 1
  .top_dy: resw 1
  .cubuk_x: resw 1
  .cubuk_y: resw 1
  .cubuk_dx: resw 1
  .cubuk_genisligi: resw 1
  .puan_isareti resb PUAN_HANE_SAYISI
endstruc

baslangic:
    
    mov ax, 0x13 ; VGA modu 0x13 te 256 tane renk
    int 0x10
    
    xor ax, ax
    mov es, ax
    mov ds, ax
    mov cx, oyun_size ;oyun adlı değişken isminin içindeki bütün eklentilerin büyüklüğünü cl kaydına yükler
    mov si, ilk_oyun_durumu
    mov di, oyun_durumu
    rep movsb
    
    mov dword [0x0070], ekrana_ciz
.loop:
    hlt
    mov ah, 0x1 ;tuş vuruşunu kontrol eder
    int 0x16
    jz .loop

    xor ah, ah
    int 0x16

    cmp al, 'a' ; "a" ya basıldığı zaman sola git
    jz .sola_surukle

    cmp al, 'd' ; "d" ye basıldığı zaman sağa git
    jz .saga_surukle

    cmp al, ' ' ; " " basıldığı zaman oyunu durdur
    jz .durdur

    cmp al, 'b' ; "b" basıldığı zaman oyunu yeniden başlat
    jz baslangic

    jmp .loop
.sola_surukle:
    mov word [oyun_durumu + oyun.cubuk_dx], - CUBUK_HIZI
    jmp .loop
.saga_surukle:
    mov word [oyun_durumu + oyun.cubuk_dx], CUBUK_HIZI
    jmp .loop
.durdur:
    not byte [oyun_durumu + oyun.surerlilik]
    jmp .loop

ekrana_ciz:
    pusha

    xor ax, ax
    mov ds, ax

    mov es, ax
    mov ah, 0x13
    mov bx, 0x000f
    mov cl, PUAN_HANE_SAYISI ; oluşacak hane sayısını cl kaydına yükler
    xor dx, dx
    mov bp, oyun_durumu + oyun.puan_isareti
    int 10h

    mov ax, VGA
    mov es, ax

    test byte [oyun_durumu + oyun.surerlilik], 1
    jz oyunu_durdur

oyunu_calisitr:
    mov al, ARKA_PLAN_RENGI ;arka plan rengini al kaydına yükle
    call cubuk_ciz
    call top_ciz

 
    mov ax, word [oyun_durumu + oyun.top_x]
    cmp ax, 0 ; eğer top_x <= 0  koşullu veya top_x >=IS - TOP_GENİŞLİĞİ
    jle .neg_top_dx ; top_dx değerini negatif yap

    cmp ax, GENISLIK - TOP_GENISLIGI
    jl .top_x_sutun_sonu

.neg_top_dx:
    neg word [oyun_durumu + oyun.top_dx]

.top_x_sutun_sonu:
    mov ax, word [oyun_durumu + oyun.top_y]
    cmp ax, YUKSEKLİK - TOP_YUKSEKLIGI ; eğer top_y >= YÜKSEKLİK - TOP_GENİŞLİĞİ
    jge .oyun_bitti ; oyun bitti satırına gider

    cmp ax, 0 ; değilse eğer top_y <= 0
    jg .top_y_sutun_sonu ; top_dy değerini negatif yap

    neg word [oyun_durumu + oyun.top_dy]

.top_y_sutun_sonu:
    xor ax, ax
    cmp word [oyun_durumu + oyun.cubuk_x], ax ; eğer çubuk_x <= 0 koşullu veya cubuk_x >=IS - ÇUBUK_GENİŞLİĞİ
    jle .neg_cubuk_dx ; çubuk_dx değerini negatif yap

    ; çarptığı taraftan geri seksin
    mov ax,GENISLIK
    sub ax, word [oyun_durumu + oyun.cubuk_genisligi]
    cmp word [oyun_durumu + oyun.cubuk_x], ax
    jl .cubuk_x_satir

.neg_cubuk_dx:
    neg word [oyun_durumu + oyun.cubuk_dx]
    mov word [oyun_durumu + oyun.cubuk_x], ax

.cubuk_x_satir:
    mov bx, word [oyun_durumu + oyun.top_x]
    cmp word [oyun_durumu + oyun.cubuk_x], bx ; eğer çubuk_x <= top_x koşullu ve top_x - çubuk_x <= ÇUBUK_GENİŞLİĞİ - TOP_GENİŞLİĞİ
    jg .yakalayamama

    sub bx, word [oyun_durumu + oyun.cubuk_x]
    mov ax, word [oyun_durumu + oyun.cubuk_genisligi]
    sub ax, TOP_GENISLIGI
    cmp bx, ax
    jg .yakalayamama

    
    mov ax, [oyun_durumu + oyun.cubuk_y]
    cmp word [oyun_durumu + oyun.top_y], ax ; eğer top_y > çubuk_y => görmezden gelicektir
    jg .yakalamanin_sonucunda

   
    sub ax, TOP_YUKSEKLIGI / 2
    cmp word [oyun_durumu + oyun.top_y], ax ; eğer top_y >= çubuk_y - TOP_GENİŞLİĞİ / 2 => yakalama
    jge .yakalama

    
    sub ax, TOP_YUKSEKLIGI / 2
    cmp word [oyun_durumu + oyun.top_y], ax
    jl .yakalamanin_sonucunda

.ziplama:
    mov word [oyun_durumu + oyun.top_dy], -TOP_HIZI
    mov word [oyun_durumu + oyun.top_dx], TOP_HIZI
    mov ax, word [oyun_durumu + oyun.cubuk_dx]
    test ax, ax
    jns .puan
    neg word [oyun_durumu + oyun.top_dx]
    jmp .puan
.yakalama:
    mov word [oyun_durumu + oyun.top_dy], 0
    
.puan:
    mov si, PUAN_HANE_SAYISI
.loop:
    inc byte [oyun_durumu + oyun.puan_isareti + si - 1]
    cmp byte [oyun_durumu + oyun.puan_isareti + si - 1], '9'
    jle .end
    mov byte [oyun_durumu + oyun.puan_isareti + si - 1], '0'
    dec si
    jz .end
    jmp .loop
.end:

    cmp word [oyun_durumu + oyun.cubuk_genisligi], 20
    jle .yakalamanin_sonucunda
    dec word [oyun_durumu + oyun.cubuk_genisligi]
    jmp .yakalamanin_sonucunda

.yakalayamama:
    cmp word [oyun_durumu + oyun.top_dy], 0
    jnz .yakalamanin_sonucunda
    mov word [oyun_durumu + oyun.top_dy], -TOP_HIZI
.yakalamanin_sonucunda:


    ; top_x += top_dx
    mov ax, [oyun_durumu + oyun.top_dx]
    add [oyun_durumu + oyun.top_x], ax

    ; top_y += top_dy
    mov ax, [oyun_durumu + oyun.top_dy]
    add [oyun_durumu + oyun.top_y], ax

    ; çubuk_x += çubuk_dx
    mov ax, [oyun_durumu + oyun.cubuk_dx]
    add [oyun_durumu + oyun.cubuk_x], ax

    mov al, CUBUK_RENGI
    call cubuk_ciz

    mov al, TOP_RENGI
    call top_ciz

    jmp oyunu_durdur
.oyun_bitti:
    xor ax, ax
    mov es, ax
    mov ah, 0x13
    mov bx, 0x0004
    ; ch = 0  cl = oyun_bitti_yazısı_uzunluğu
    mov cx, oyun_bitti_yazisi_uzunlugu  
    ; dh = HIZA / 2  dl = SÜTÜN / 2 - oyun_bitti_yazısı_uzunluğu / 2
    mov dx, (HIZA / 2) << 8 | (SUTUN / 2 - oyun_bitti_yazisi_uzunlugu / 2)
    mov bp, oyun_bitti_yazisi
    int 10h
    mov ah, 0x13
    mov bx, 0x000f
    mov cx, baskan_uzunlugu
    mov dx, (HIZA / 2) << 9 | (SUTUN / 2 - baskan_uzunlugu / 2)
    mov bp, baskan
    int 10h
    mov byte [oyun_durumu + oyun.surerlilik], 0

oyunu_durdur:
    popa
    iret

cubuk_ciz:
    mov cx, word [oyun_durumu + oyun.cubuk_genisligi]
    mov bx, CUBUK_YUKSEKLIGI
    mov si, oyun_durumu + oyun.cubuk_x
    jmp doldur

top_ciz:
    mov cx, TOP_GENISLIGI
    mov bx, TOP_YUKSEKLIGI
    mov si, oyun_durumu + oyun.top_x

doldur:
    ; al = renk , cx = genişlik , bx = yükseklik , si = top_x yada çubuk_x işaretçi atıyor  di = düz_y *IS + düz_x
    imul di, [si + 2],GENISLIK
    add di, [si]

.hiza:
    push cx
    rep stosb
    pop cx
    sub di, cx
    add di,GENISLIK
    dec bx
    jnz .hiza

    ret

ilk_oyun_durumu:
istruc oyun
  at oyun.surerlilik, db 1
  at oyun.top_x, dw 30
  at oyun.top_y, dw 30
  at oyun.top_dx, dw TOP_HIZI
  at oyun.top_dy, dw -TOP_HIZI
  at oyun.cubuk_x, dw 10
  at oyun.cubuk_y, dw YUKSEKLİK - CUBUK_UZUNLUGU
  at oyun.cubuk_dx, dw CUBUK_HIZI
  at oyun.cubuk_genisligi, dw 100
  at oyun.puan_isareti, times PUAN_HANE_SAYISI db '0'
iend

oyun_bitti_yazisi: db 'Oyun Bitti',
oyun_bitti_yazisi_uzunlugu equ $ - oyun_bitti_yazisi
baskan: db '(c) 2023 BASKAN',
baskan_uzunlugu: equ $ - baskan


    times 510 - ($-$$) db 0
oyun_durumu:
    
    dw 0xaa55

    