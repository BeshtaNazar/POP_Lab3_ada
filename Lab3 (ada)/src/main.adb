with Ada.Text_IO, GNAT.Semaphores;
use Ada.Text_IO, GNAT.Semaphores;

with Ada.Containers.Indefinite_Doubly_Linked_Lists;
use Ada.Containers;

procedure Main is
   package String_Lists is new Indefinite_Doubly_Linked_Lists (String);
   use String_Lists;

   procedure Starter (Storage_Size : in Integer; Producers_number : in Integer; Consumers_number : in Integer) is
      Storage : List;

      Access_Storage : Counting_Semaphore (1, Default_Ceiling);
      Full_Storage   : Counting_Semaphore (Storage_Size, Default_Ceiling);
      Empty_Storage  : Counting_Semaphore (0, Default_Ceiling);

      Products_number : Integer :=0;
      Part_products : Integer :=0;
      Count_products : Integer :=1;
      task type Producer is
         entry Start(Item_Numbers : in Integer);
      end Producer;

      task type Consumer is
         entry Start(Item_Numbers : in Integer);
      end Consumer;

      task body Producer is
         Item_Numbers : Integer;
      begin
         accept Start (Item_Numbers : in Integer) do
            Producer.Item_Numbers := Item_Numbers;
         end Start;

         for i in 1 .. Item_Numbers loop
            Full_Storage.Seize;
            Access_Storage.Seize;

            Storage.Append ("item " & Count_products'Img);
            Put_Line ("Added item " & Count_products'Img);


            Access_Storage.Release;
            Empty_Storage.Release;
            Count_products:=Count_products+1;
            delay 1.5;
         end loop;

      end Producer;

      task body Consumer is
         Item_Numbers : Integer;
      begin
         accept Start (Item_Numbers : in Integer) do
            Consumer.Item_Numbers := Item_Numbers;
         end Start;

         for i in 1..Item_Numbers loop
            Empty_Storage.Seize;
            Access_Storage.Seize;

            declare
               item : String := First_Element (Storage);
            begin
               Put_Line ("Took " & item);
            end;

            Storage.Delete_First;

            Access_Storage.Release;
            Full_Storage.Release;

            delay 2.0;
         end loop;

      end Consumer;

      Producers : Array (1..Producers_number) of Producer;

      Consumers : Array (1..Consumers_number) of Consumer;

   begin
      for i in Producers'Range loop
         Producers(i).Start (i);
         Products_number:=Products_number+(i);
      end loop;
      Part_products:=Products_number/Consumers_number;
      if Part_products>=1 then
         for i in 1..(Consumers_number-1) loop
            Consumers(i).Start(Part_products);
            delay 1.0;
         end loop;
         if Products_number=Consumers_number then
            Consumers(Consumers_number).Start(1);
         else
            Consumers(Consumers_number).Start(Products_number-(Consumers_number*Part_products)+Part_products);
         end if;

      else
         for i in 1..Products_number loop
            Consumers(i).Start(1);
            delay 1.0;
         end loop;
         for i in (Products_number+1)..Consumers_number loop
            Consumers(i).Start(0);
         end loop;
      end if;
   end Starter;

begin

   Starter (1, 3, 2);
end Main;
