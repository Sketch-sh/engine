let () = begin
  Js.export "berror" (
    object%js
      val parse = RtopEntry.parse
    end);
end
