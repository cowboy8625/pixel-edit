use iced::executor;
use iced::mouse;
use iced::widget::canvas::{Cache, Geometry, Path};
use iced::widget::{canvas, container};
use iced::{
    Application, Color, Command, Element, Length, Point, Rectangle, Renderer, Settings, Size, Theme,
};
mod app_canvas;
mod brush;
use app_canvas::AppCanvas;
use brush::Brush;

pub fn main() -> iced::Result {
    PixelEditor::run(Settings {
        antialiasing: true,
        ..Settings::default()
    })
}

struct PixelEditor {
    canvas: Cache,
    positions: Vec<Point>,
    app_canvas: AppCanvas,
    brush: Brush,
}

#[derive(Debug, Clone, Copy)]
enum Message {
    Placed(Point),
    Zoom(mouse::ScrollDelta),
}

impl Application for PixelEditor {
    type Executor = executor::Default;
    type Message = Message;
    type Theme = Theme;
    type Flags = ();

    fn new(_flags: ()) -> (Self, Command<Message>) {
        (
            Self {
                canvas: Cache::default(),
                positions: Vec::new(),
                app_canvas: AppCanvas {
                    canvas_size: Size::new(16.0, 16.0),
                    cell_size: Size::new(16.0, 16.0),
                    zoom: 1.0,
                },
                brush: Brush {
                    color: Color::BLACK,
                    size: Size::new(1.0, 1.0),
                },
            },
            Command::none(),
        )
    }

    fn title(&self) -> String {
        String::from("Clock - Iced")
    }

    fn update(&mut self, message: Message) -> Command<Message> {
        match message {
            Message::Placed(point) => {
                self.positions.push(point);
                self.canvas.clear();
            }
            Message::Zoom(zoom) => {
                if let mouse::ScrollDelta::Lines { y, .. } = zoom {
                    self.app_canvas.zoom += y * 0.1;
                };
            }
        }

        Command::none()
    }

    fn view(&self) -> Element<Message> {
        let canvas = canvas(self as &Self)
            .width(Length::Fixed(self.app_canvas.width()))
            .height(Length::Fixed(self.app_canvas.height()));

        container(canvas)
            .width(Length::Fill)
            .height(Length::Fill)
            .center_x()
            .center_y()
            .into()
    }
}

impl canvas::Program<Message> for PixelEditor {
    type State = Option<Message>;

    fn update(
        &self,
        state: &mut Self::State,
        event: canvas::Event,
        bounds: Rectangle,
        cursor: mouse::Cursor,
    ) -> (canvas::event::Status, Option<Message>) {
        match event {
            canvas::Event::Mouse(mouse::Event::ButtonPressed(mouse::Button::Left)) => {
                *state = cursor
                    .position()
                    .map(|point| {
                        Point::new(
                            ((point.x - bounds.x) / self.app_canvas.cell_size().width).floor(),
                            ((point.y - bounds.y) / self.app_canvas.cell_size().height).floor(),
                        )
                    })
                    .map(Message::Placed);
                (canvas::event::Status::Captured, state.take())
            }
            canvas::Event::Mouse(mouse::Event::WheelScrolled { delta }) => {
                println!("{:?}", delta);
                *state = Some(Message::Zoom(delta));
                (canvas::event::Status::Captured, state.take())
            }
            _ => (canvas::event::Status::Ignored, state.take()),
        }
    }

    fn draw(
        &self,
        _state: &Self::State,
        renderer: &Renderer,
        _theme: &Theme,
        bounds: Rectangle,
        _cursor: mouse::Cursor,
    ) -> Vec<Geometry> {
        let canvas = self.canvas.draw(renderer, bounds.size(), |frame| {
            let background = Path::rectangle(Point::ORIGIN, frame.size());
            frame.fill(&background, Color::from_rgb(0.8, 0.8, 0.8));

            for position in &self.positions {
                let pos = Point::new(
                    position.x * self.app_canvas.cell_size().width,
                    position.y * self.app_canvas.cell_size().height,
                );
                let cell = Path::rectangle(pos, self.app_canvas.cell_size());
                frame.fill(&cell, self.brush.color);
            }
        });

        vec![canvas]
    }
}
